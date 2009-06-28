module TypusHelper

  ##
  # Applications list on the dashboard
  #
  def applications

    returning(String.new) do |html|

      Typus.applications.each do |app|

        available = Typus.application(app).map do |resource|
                      resource if @current_user.resources.include?(resource)
                    end
        next if available.compact.empty?

        html << <<-HTML
<table>
<tr>
<th colspan="2">#{app}</th>
</tr>
        HTML

        available.compact.each do |model|
          description = Typus.module_description(model)
          admin_items_path = { :controller => "admin/#{model.tableize}" }
          new_admin_item_path = { :controller => "admin/#{model.tableize}", :action => 'new'}
          html << <<-HTML
<tr class="#{cycle('even', 'odd')}">
<td>#{link_to _(model.constantize.human_name.pluralize), admin_items_path}<br /><small>#{description}</small></td>
<td class="right"><small>
#{link_to _("Add"), new_admin_item_path if @current_user.can_perform?(model, 'create')}
</small></td>
</tr>
          HTML
        end

        html << <<-HTML
</table>
        HTML

      end

    end

  end

  ##
  # Resources (wich are not models) on the dashboard.
  #
  def resources

    available = Typus.resources.map do |resource|
                  resource if @current_user.resources.include?(resource)
                end
    return if available.compact.empty?

    returning(String.new) do |html|

      html << <<-HTML
<table>
<tr>
<th colspan="2">#{_("Resources")}</th>
</tr>
      HTML

      available.compact.each do |resource|

        resource_path = { :controller => "admin/#{resource.underscore}" }

        html << <<-HTML
<tr class="#{cycle('even', 'odd')}">
<td>#{link_to _(resource.humanize), resource_path}</td>
<td align="right" style="vertical-align: bottom;"></td>
</tr>
        HTML

      end

      html << <<-HTML
</table>
      HTML

    end

  end

  def typus_block(*args)

    options = args.extract_options!

    partials_path = "admin/#{options[:location]}"
    resources_partials_path = 'admin/resources'

    partials = ActionController::Base.view_paths.map do |view_path|
      path = Rails.vendor_rails? ? view_path.path : "#{Rails.root}/#{view_path}"
      Dir["#{path}/#{partials_path}/*"].map { |f| File.basename(f, '.html.erb') }
    end.flatten
    resources_partials = Dir["#{Rails.root}/app/views/#{resources_partials_path}/*"].map { |f| File.basename(f, '.html.erb') }

    partial = "_#{options[:partial]}"

    path = if partials.include?(partial) then partials_path
           elsif resources_partials.include?(partial) then resources_partials_path
           end

    render :partial => "#{path}/#{options[:partial]}" if path

  end

  def page_title(action = params[:action])
    crumbs = [ ]
    crumbs << @resource[:class].human_name.pluralize if @resource
    crumbs << _(action.humanize) unless %w( index ).include?(action)
    return "#{Typus::Configuration.options[:app_name]} - " + crumbs.compact.map { |x| x }.join(' &rsaquo; ')
  end

  def header

    if ActionController::Routing::Routes.named_routes.routes.keys.include?(:root)
      link_to_site = "<li>#{link_to _("View site"), root_path, :target => 'blank'}</li>"
    end

    link_to_dashboard = "<li>#{link_to _("Dashboard"), admin_dashboard_path}</li>"

    <<-HTML
<h1>#{Typus::Configuration.options[:app_name]}</h1>
<ul>
  #{link_to_dashboard}
  #{link_to_site}
</ul>
    HTML

  end

  def login_info(user = @current_user)

    admin_edit_typus_user_path = { :controller => "admin/#{Typus::Configuration.options[:user_class_name].tableize}", 
                                   :action => 'edit', 
                                   :id => user.id }

    <<-HTML
<ul>
  <li>#{_("Logged as")} #{link_to user.name, admin_edit_typus_user_path, :title => "#{user.email} (#{user.role})"}</li>
  <li>#{link_to _("Sign out"), admin_sign_out_path }</li>
</ul>
    HTML

  end

  def display_flash_message(message = flash)

    return if message.empty?
    flash_type = message.keys.first

    <<-HTML
<div id="flash" class="#{flash_type}">
  <p>#{message[flash_type]}</p>
</div>
    HTML

  end

  def typus_message(message, html_class = 'notice')
    <<-HTML
<div id="flash" class="#{html_class}">
  <p>#{message}</p>
</div>
    HTML
  end

  def locales(uri = admin_set_locale_path)

    return unless Typus.locales.many?

    locale_links = Typus.locales.map { |l| "<a href=\"#{uri}?locale=#{l.last}\">#{l.first.downcase}</a>" }

    <<-HTML
<p>#{_("Set language to")} #{locale_links.join(', ')}.</p>
    HTML

  end

end