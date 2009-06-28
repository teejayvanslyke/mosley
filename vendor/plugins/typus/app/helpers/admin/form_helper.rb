module Admin::FormHelper

  def build_form(fields)

    options = { :start_year => @resource[:class].typus_options_for(:start_year), 
                :end_year => @resource[:class].typus_options_for(:end_year), 
                :minute_step => @resource[:class].typus_options_for(:minute_step) }

    returning(String.new) do |html|
      html << (error_messages_for :item, :header_tag => 'h3')
      html << '<ul>'
      fields.each do |key, value|
        if template = @resource[:class].typus_template(key)
          html << typus_template_field(key, template, options)
          next
        end
        case value
        when :belongs_to:      html << typus_belongs_to_field(key)
        when :boolean:         html << typus_boolean_field(key)
        when :date:            html << typus_date_field(key, options)
        when :datetime:        html << typus_datetime_field(key, options)
        when :file:            html << typus_file_field(key)
        when :password:        html << typus_password_field(key)
        when :selector:        html << typus_selector_field(key)
        when :text:            html << typus_text_field(key)
        when :time:            html << typus_time_field(key, options)
        when :tree:            html << typus_tree_field(key)
        else
          html << typus_string_field(key)
        end
      end
      html << '</ul>'
    end
  end

  def typus_belongs_to_field(attribute)

    ##
    # We only can pass parameters to 'new' and 'edit', so this hack makes
    # the work to replace the current action.
    #
    params[:action] = (params[:action] == 'create') ? 'new' : params[:action]

    back_to = '/' + [ params[:controller], params[:action], params[:id] ].compact.join('/')

    related = @resource[:class].reflect_on_association(attribute.to_sym).class_name.constantize
    related_fk = @resource[:class].reflect_on_association(attribute.to_sym).primary_key_name

    message = [ _("Are you sure you want to leave this page?"),
                _("If you have made any changes to the fields without clicking the Save/Update entry button, your changes will be lost."), 
                _("Click OK to continue, or click Cancel to stay on this page.") ]

    returning(String.new) do |html|

      if related.respond_to?(:roots)
        html << typus_tree_field(related_fk, related.roots, related_fk)
      else
        html << <<-HTML
<li><label for="item_#{attribute}">#{_(related_fk.humanize)}
    <small>#{link_to _("Add"), { :controller => "admin/#{related.class_name.tableize}", :action => 'new', :back_to => back_to, :selected => related_fk }, :confirm => message.join("\n\n") if @current_user.can_perform?(related, 'create')}</small>
    </label>
#{select :item, related_fk, related.find(:all, :order => related.typus_order_by).collect { |p| [p.typus_name, p.id] }, { :include_blank => true }, { :disabled => attribute_disabled?(attribute) } }</li>
        HTML
      end

    end

  end

  def typus_boolean_field(attribute)
    attribute_name = attribute.gsub(/\?$/,'')
    <<-HTML
<li><label for="item_#{attribute_name}">#{@resource[:class].human_attribute_name(attribute)}</label>
#{check_box :item, attribute_name} #{_("Checked if active")}</li>
    HTML
  end

  def typus_date_field(attribute, options)
    <<-HTML
<li><label for="item_#{attribute}">#{@resource[:class].human_attribute_name(attribute)}</label>
#{date_select :item, attribute, options, { :disabled => attribute_disabled?(attribute)} }</li>
    HTML
  end

  def typus_datetime_field(attribute, options)
    <<-HTML
<li><label for="item_#{attribute}">#{@resource[:class].human_attribute_name(attribute)}</label>
#{datetime_select :item, attribute, options, {:disabled => attribute_disabled?(attribute)}}</li>
    HTML
  end

  def typus_file_field(attribute)

    attribute_display = attribute.split('_file_name').first

    <<-HTML
<li><label for="item_#{attribute}">#{_(attribute_display.humanize)}</label>
#{file_field :item, attribute.split("_file_name").first, :disabled => attribute_disabled?(attribute)}</li>
    HTML

  end

  def typus_password_field(attribute)
    <<-HTML
<li><label for="item_#{attribute}">#{@resource[:class].human_attribute_name(attribute)}</label>
#{password_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute)}</li>
    HTML
  end

  def typus_selector_field(attribute)
    returning(String.new) do |html|
      options = []
      @resource[:class].send(attribute).each do |option|
        case option.kind_of?(Array)
        when true
          selected = (@item.send(attribute).to_s == option.last.to_s) ? 'selected' : ''
          options << "<option #{selected} value=\"#{option.last}\">#{option.first}</option>"
        else
          selected = (@item.send(attribute).to_s == option.to_s) ? 'selected' : ''
          options << "<option #{selected} value=\"#{option}\">#{option}</option>"
        end
      end
      html << <<-HTML
<li><label for="item_#{attribute}">#{@resource[:class].human_attribute_name(attribute)}</label>
<select id="item_#{attribute}" #{attribute_disabled?(attribute) ? 'disabled="disabled"' : ''} name="item[#{attribute}]">
<option value=""></option>
#{options.join("\n")}
</select></li>
      HTML
    end
  end

  def typus_text_field(attribute)
    <<-HTML
<li><label for="item_#{attribute}">#{@resource[:class].human_attribute_name(attribute)}</label>
#{text_area :item, attribute, :class => 'text', :rows => @resource[:class].typus_options_for(:form_rows), :disabled => attribute_disabled?(attribute)}</li>
    HTML
  end

  def typus_time_field(attribute, options)
    <<-HTML
<li><label for="item_#{attribute}">#{@resource[:class].human_attribute_name(attribute)}</label>
#{time_select :item, attribute, options, {:disabled => attribute_disabled?(attribute)}}</li>
    HTML
  end

  def typus_tree_field(attribute, items = @resource[:class].roots, attribute_virtual = 'parent_id')
    <<-HTML
<li><label for="item_#{attribute}">#{@resource[:class].human_attribute_name(attribute)}</label>
<select id="item_#{attribute}" #{attribute_disabled?(attribute) ? 'disabled="disabled"' : ''} name="item[#{attribute}]">
  <option value=""></option>
  #{expand_tree_into_select_field(items, attribute_virtual)}
</select></li>
    HTML
  end

  def typus_string_field(attribute)

    # Read only fields.
    if @resource[:class].typus_field_options_for(:read_only).include?(attribute)
      value = 'read_only' if %w( edit ).include?(params[:action])
    end

    # Auto generated fields.
    if @resource[:class].typus_field_options_for(:auto_generated).include?(attribute)
      value = 'auto_generated' if %w( new edit ).include?(params[:action])
    end

    comment = %w( read_only auto_generated ).include?(value) ? "<small>#{value} field</small>".humanize : ''

    attribute_humanized = @resource[:class].human_attribute_name(attribute)
    attribute_humanized += " (#{attribute})" if attribute.include?('_id')

    <<-HTML
<li><label for="item_#{attribute}">#{attribute_humanized}#{comment}</label>
#{text_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute) }</li>
    HTML

  end

  def typus_relationships

    # OPTIMIZE
    @back_to = '/' + [ params[:controller], params[:action], params[:id] ].compact.join('/')

    returning(String.new) do |html|
      @resource[:class].typus_defaults_for(:relationships).each do |relationship|

        association = @resource[:class].reflect_on_association(relationship.to_sym)

        next if !@current_user.can_perform?(association.class_name.constantize, 'read')

        case association.macro
        when :has_and_belongs_to_many
          html << typus_form_has_and_belongs_to_many(relationship)
        when :has_many
          html << typus_form_has_many(relationship)
        when :has_one
          html << typus_form_has_one(relationship)
        end

      end
    end

  end

  def typus_form_has_many(field)
    returning(String.new) do |html|

      model_to_relate = @resource[:class].reflect_on_association(field.to_sym).class_name.constantize
      model_to_relate_as_resource = model_to_relate.name.tableize

      reflection = @resource[:class].reflect_on_association(field.to_sym)
      association = reflection.macro
      foreign_key = reflection.through_reflection ? reflection.primary_key_name.pluralize : reflection.primary_key_name

      link_options = { :controller => "admin/#{field}", 
                       :action => 'new', 
                       :back_to => "#{@back_to}##{field}", 
                       :resource => @resource[:self].singularize, 
                       :resource_id => @item.id, 
                       foreign_key => @item.id }

      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships">
  <h2>
  #{link_to model_to_relate.human_name.pluralize, { :controller => "admin/#{model_to_relate_as_resource}", foreign_key => @item.id }, :title => _("{{model}} filtered by {{filtered_by}}", :model => model_to_relate.human_name.pluralize, :filtered_by => @item.typus_name)}
  <small>#{link_to _("Add new"), link_options if @current_user.can_perform?(model_to_relate, 'create')}</small>
  </h2>
      HTML

      conditions = if model_to_relate.typus_options_for(:only_user_items) && !@current_user.is_root?
                    { Typus.user_fk => @current_user }
                  end

      items = @resource[:class].find(params[:id]).send(field).find(:all, :order => model_to_relate.typus_order_by, :conditions => conditions)

      unless items.empty?
        options = { :back_to => "#{@back_to}##{field}", :resource => @resource[:self], :resource_id => @item.id }
        html << build_list(model_to_relate, 
                           model_to_relate.typus_fields_for(:relationship), 
                           items, 
                           model_to_relate_as_resource, 
                           options, 
                           association)
      else
        html << <<-HTML
  <div id="flash" class="notice"><p>#{_("There are no {{records}}.", :records => model_to_relate.human_name.pluralize.downcase)}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML
    end
  end

  def typus_form_has_and_belongs_to_many(field)
    returning(String.new) do |html|

      model_to_relate = @resource[:class].reflect_on_association(field.to_sym).class_name.constantize
      model_to_relate_as_resource = model_to_relate.name.tableize

      reflection = @resource[:class].reflect_on_association(field.to_sym)
      association = reflection.macro

      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships">
  <h2>
  #{link_to model_to_relate.human_name.pluralize, :controller => "admin/#{model_to_relate_as_resource}"}
  <small>#{link_to _("Add new"), :controller => field, :action => 'new', :back_to => @back_to, :resource => @resource[:self], :resource_id => @item.id if @current_user.can_perform?(model_to_relate, 'create')}</small>
  </h2>
      HTML
      items_to_relate = (model_to_relate.find(:all) - @item.send(field))
      unless items_to_relate.empty?
        html << <<-HTML
  #{form_tag :action => 'relate', :id => @item.id}
  #{hidden_field :related, :model, :value => model_to_relate}
  <p>#{ select :related, :id, items_to_relate.collect { |f| [f.typus_name, f.id] }.sort_by { |e| e.first } } &nbsp; #{submit_tag _("Add"), :class => 'button'}</p>
  </form>
        HTML
      end
      items = @resource[:class].find(params[:id]).send(field)
      unless items.empty?
        html << build_list(model_to_relate, 
                           model_to_relate.typus_fields_for(:relationship), 
                           items, 
                           model_to_relate_as_resource, 
                           {}, 
                           association)
      else
        html << <<-HTML
  <div id="flash" class="notice"><p>#{_("There are no {{records}}.", :records => model_to_relate.human_name.pluralize.downcase)}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML
    end
  end

  def typus_form_has_one(field)
    returning(String.new) do |html|

      model_to_relate = @resource[:class].reflect_on_association(field.to_sym).class_name.constantize
      model_to_relate_as_resource = model_to_relate.name.tableize

      reflection = @resource[:class].reflect_on_association(field.to_sym)
      association = reflection.macro

      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships">
  <h2>
  #{link_to model_to_relate.human_name, :controller => "admin/#{model_to_relate_as_resource}"}
  </h2>
      HTML
      items = Array.new
      items << @resource[:class].find(params[:id]).send(field) unless @resource[:class].find(params[:id]).send(field).nil?
      unless items.empty?
        options = { :back_to => @back_to, :resource => @resource[:self], :resource_id => @item.id }
        html << build_list(model_to_relate, 
                           model_to_relate.typus_fields_for(:relationship), 
                           items, 
                           model_to_relate_as_resource, 
                           options, 
                           association)
      else
        html << <<-HTML
  <div id="flash" class="notice"><p>#{_("There is no {{records}}.", :records => model_to_relate.human_name.downcase)}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML
    end
  end

  def typus_template_field(attribute, template, options = {})
    folder = Typus::Configuration.options[:templates_folder]
    template_name = File.join(folder, template)

    output = render(:partial => template_name, :locals => { :resource => @resource, :attribute => attribute, :options => options } )
    output || "#{attribute}: Can not find the template '#{template}'"
  end

  def attribute_disabled?(attribute)
    accessible = @resource[:class].accessible_attributes
    return accessible.nil? ? false : !accessible.include?(attribute)
  end

  ##
  # Tree builder when model +acts_as_tree+
  #
  def expand_tree_into_select_field(items, attribute)
    returning(String.new) do |html|
      items.each do |item|
        html << %{<option #{"selected" if @item.send(attribute) == item.id} value="#{item.id}">#{"&nbsp;" * item.ancestors.size * 8} &#92;_ #{item.typus_name}</option>\n}
        html << expand_tree_into_select_field(item.children, attribute) unless item.children.empty?
      end
    end
  end

end