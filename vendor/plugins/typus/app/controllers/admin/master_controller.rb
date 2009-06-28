class Admin::MasterController < ApplicationController

  layout 'admin'

  include Typus::Authentication
  include Typus::Format
  include Typus::Locale
  include Typus::Reloader

  if Typus::Configuration.options[:ssl]
    include SslRequirement
    ssl_required :index, :new, :create, :edit, :show, :update, :destroy, :toggle, :position, :relate, :unrelate
  end

  filter_parameter_logging :password

  before_filter :reload_config_et_roles

  before_filter :require_login

  before_filter :set_locale

  before_filter :set_resource
  before_filter :find_item, 
                :only => [ :show, :edit, :update, :destroy, :toggle, :position, :relate, :unrelate ]

  before_filter :check_ownership_of_item, 
                :only => [ :edit, :update, :destroy, :toggle, :position, :relate, :unrelate ]

  before_filter :check_if_user_can_perform_action_on_user, 
                :only => [ :edit, :update, :toggle, :destroy ]
  before_filter :check_if_user_can_perform_action_on_resource

  before_filter :set_order, 
                :only => [ :index ]
  before_filter :set_fields, 
                :only => [ :index, :new, :edit, :create, :update, :show ]

  ##
  # This is the main index of the model. With filters, conditions 
  # and more.
  #
  # By default application can respond_to html, csv and xml, but you 
  # can add your formats.
  #
  def index

    @conditions, @joins = @resource[:class].build_conditions(params)

    check_ownership_of_items if @resource[:class].typus_options_for(:only_user_items)

    respond_to do |format|
      format.html { generate_html }
      @resource[:class].typus_export_formats.each do |f|
        format.send(f) { send("generate_#{f}") }
      end
    end

  rescue Exception => error
    error_handler(error)
  end

  def new

    item_params = params.dup
    %w( controller action resource resource_id back_to selected ).each do |param|
      item_params.delete(param)
    end

    @item = @resource[:class].new(item_params.symbolize_keys)

    select_template :new

  end

  ##
  # Create new items. There's an special case when we create an 
  # item from another item. In this case, after the item is 
  # created we also create the relationship between these items. 
  #
  def create

    @item = @resource[:class].new(params[:item])

    if @item.attributes.include?(Typus.user_fk)
      @item.attributes = { Typus.user_fk => session[:typus_user_id] }
    end

    if @item.valid?
      create_with_back_to and return if params[:back_to]
      @item.save
      flash[:success] = _("{{model}} successfully created.", :model => @resource[:class].human_name)
      if @resource[:class].typus_options_for(:index_after_save)
        redirect_to :action => 'index'
      else
        redirect_to :action => @resource[:class].typus_options_for(:default_action_on_item), :id => @item.id
      end
    else
      select_template :new
    end

  end

  def edit
    item_params = params.dup
    %w( action controller model model_id back_to id resource resource_id ).each { |p| item_params.delete(p) }
    # We assign the params passed trough the url
    @item.attributes = item_params
    @previous, @next = @item.previous_and_next(item_params)
    select_template :edit
  end

  def show

    @previous, @next = @item.previous_and_next

    respond_to do |format|
      format.html { select_template :show }
      format.xml do
        fields = @resource[:class].typus_fields_for(:xml).collect { |i| i.first }
        render :xml => @item.to_xml(:only => fields)
      end
    end

  end

  def update
    if @item.update_attributes(params[:item])
      flash[:success] = _("{{model}} successfully updated.", :model => @resource[:class].human_name)
      path = if @resource[:class].typus_options_for(:index_after_save)
               params[:back_to] ? "#{params[:back_to]}##{@resource[:self]}" : { :action => 'index' }
             else
               { :action => @resource[:class].typus_options_for(:default_action_on_item), :id => @item.id, :back_to => params[:back_to] }
             end
      redirect_to path
    else
      @previous, @next = @item.previous_and_next
      select_template :edit
    end
  end

  def destroy
    @item.destroy
    flash[:success] = _("{{model}} successfully removed.", :model => @resource[:class].human_name)
    redirect_to :back
  rescue Exception => error
    error_handler(error, params.merge(:action => 'index', :id => nil))
  end

  def toggle
    if @resource[:class].typus_options_for(:toggle)
      @item.toggle!(params[:field])
      flash[:success] = _("{{model}} {{attribute}} changed.", 
                          :model => @resource[:class].human_name, 
                          :attribute => params[:field].humanize.downcase)
    else
      flash[:notice] = _("Toggle is disabled.")
    end
    redirect_to :back
  end

  ##
  # Change item position. This only works if acts_as_list is 
  # installed. We can then move items:
  #
  #   params[:go] = 'move_to_top'
  #
  # Available positions are move_to_top, move_higher, move_lower, 
  # move_to_bottom.
  #
  def position
    @item.send(params[:go])
    flash[:success] = _("Record moved {{to}}.", :to => params[:go].gsub(/move_/, '').humanize.downcase)
    redirect_to :back
  end

  ##
  # Relate a model object to another, this action is used only by the 
  # has_and_belongs_to_many relationships.
  #
  def relate

    resource_class = params[:related][:model].constantize
    resource_tableized = params[:related][:model].tableize

    @item.send(resource_tableized) << resource_class.find(params[:related][:id])

    flash[:success] = _("{{model_a}} related to {{model_b}}.", 
                        :model_a => resource_class.human_name, 
                        :model_b => @resource[:class].human_name)

    redirect_to :action => @resource[:class].typus_options_for(:default_action_on_item), 
                :id => @item.id, 
                :anchor => resource_tableized

  end

  ##
  # Remove relationship between models.
  #
  def unrelate

    resource_class = params[:resource].classify.constantize
    resource = resource_class.find(params[:resource_id])

    case params[:association]
    when 'has_and_belongs_to_many'
      @item.send(resource_class.table_name).delete(resource)
      message = "{{model_a}} unrelated from {{model_b}}."
    when 'has_many', 'has_one'
      resource.destroy
      message = "{{model_a}} removed from {{model_b}}."
    end

    flash[:success] = _(message, :model_a => resource_class.human_name, :model_b => @resource[:class].human_name)

    redirect_to :controller => @resource[:self], 
                :action => @resource[:class].typus_options_for(:default_action_on_item), 
                :id => @item.id, 
                :anchor => resource_class.table_name

  end

private

  def set_resource
    resource = params[:controller].split('/').last
    @resource = { :self => resource, :class => resource.classify.constantize }
  rescue Exception => error
    error_handler(error)
  end

  ##
  # Find model when performing an edit, update, destroy, relate, 
  # unrelate ...
  #
  def find_item
    @item = @resource[:class].find(params[:id])
  end

  ##
  # If item is owned by another user, we only can perform a 
  # show action on the item. Updated item is also blocked.
  #
  #   before_filter :check_ownership_of_item, :only => [ :edit, :update, :destroy ]
  #
  def check_ownership_of_item

    # If current_user is a root user, by-pass.
    return if @current_user.is_root?

    # OPTIMIZE: `typus_users` is currently hard-coded. We should find a good name for this option.
    if @item.respond_to?('typus_users') && !@item.send('typus_users').include?(@current_user) ||
       @item.respond_to?(Typus.user_fk) && !(@item.send(Typus.user_fk) == session[:typus_user_id])
       flash[:notice] = _("You don't have permission to access this item.")
       redirect_to :back
    end

  end

  def check_ownership_of_items

    # If current_user is a root user, by-pass.
    return if @current_user.is_root?

    # If current user is not root and @resource has a foreign_key which 
    # is related to the logged user (Typus.user_fk) we only show the user 
    # related items.
    if @resource[:class].columns.map { |u| u.name }.include?(Typus.user_fk)
      condition = { Typus.user_fk => @current_user }
      @conditions = @resource[:class].merge_conditions(@conditions, condition)
    end

  end

  def set_fields
    @fields = case params[:action]
              when 'index'
                @resource[:class].typus_fields_for(:list)
              when 'new', 'edit', 'create', 'update'
                @resource[:class].typus_fields_for(:form)
              else
                @resource[:class].typus_fields_for(params[:action])
              end
  end

  def set_order
    params[:sort_order] ||= 'desc'
    @order = params[:order_by] ? "#{@resource[:class].table_name}.#{params[:order_by]} #{params[:sort_order]}" : @resource[:class].typus_order_by
  end

  def select_template(template, resource = @resource[:self])
    folder = (File.exist?("app/views/admin/#{resource}/#{template}.html.erb")) ? resource : 'resources'
    render "admin/#{folder}/#{template}"
  end

  ##
  # When <tt>params[:back_to]</tt> is defined this action is used.
  #
  # - <tt>has_and_belongs_to_many</tt> relationships.
  # - <tt>has_many</tt> relationships (polymorphic ones).
  #
  def create_with_back_to

    if params[:resource] && params[:resource_id]
      resource_class = params[:resource].classify.constantize
      resource_id = params[:resource_id]
      resource = resource_class.find(resource_id)
      association = @resource[:class].reflect_on_association(params[:resource].to_sym).macro rescue :polymorphic
    else
      association = :has_many
    end

    case association
    when :belongs_to
      @item.save
    when :has_and_belongs_to_many
      @item.save
      @item.send(params[:resource]) << resource
    when :has_many
      @item.save
      message = _("{{model}} successfully created.", :model => @resource[:class].human_name)
      path = "#{params[:back_to]}?#{params[:selected]}=#{@item.id}"
    when :polymorphic
      resource.send(@item.class.name.tableize).create(params[:item])
      path = "#{params[:back_to]}##{@resource[:self]}"
    end

    flash[:success] = message || _("{{model_a}} successfully assigned to {{model_b}}.", 
                                 :model_a => @item.class, 
                                 :model_b => resource_class.name)
    redirect_to path || params[:back_to]

  end

  def error_handler(error, path = admin_dashboard_path)
    raise error unless Rails.env.production?
    flash[:error] = "#{error.message} (#{@resource[:class]})"
    redirect_to path
  end

end