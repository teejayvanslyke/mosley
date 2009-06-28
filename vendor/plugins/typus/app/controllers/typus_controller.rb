class TypusController < ApplicationController

  layout :select_layout

  include Typus::Authentication
  include Typus::Locale
  include Typus::QuickEdit
  include Typus::Reloader

  if Typus::Configuration.options[:ssl]
    include SslRequirement
    ssl_required :sign_in, :sign_out, 
                 :dashboard, 
                 :recover_password, :reset_password
  end

  filter_parameter_logging :password

  before_filter :set_locale

  before_filter :reload_config_et_roles
  before_filter :require_login, 
                :except => [ :sign_up, :sign_in, :sign_out, 
                             :recover_password, :reset_password, 
                             :quick_edit ]

  before_filter :check_if_user_can_perform_action_on_resource_without_model, 
                :except => [ :sign_up, :sign_in, :sign_out, 
                             :dashboard, 
                             :recover_password, :reset_password, 
                             :quick_edit, :set_locale ]

  before_filter :recover_password_disabled?, 
                :only => [ :recover_password, :reset_password ]

  def dashboard
    flash[:notice] = _("There are not defined applications in config/typus/*.yml.") if Typus.applications.empty?
  end

  def sign_in

    redirect_to admin_sign_up_path and return if Typus.user_class.count.zero?

    if request.post?
      if user = Typus.user_class.authenticate(params[:user][:email], params[:user][:password])
        session[:typus_user_id] = user.id
        redirect_to params[:back_to] || admin_dashboard_path
      else
        flash[:error] = _("The email and/or password you entered is invalid.")
        redirect_to admin_sign_in_path
      end
    end

  end

  def sign_out
    session[:typus_user_id] = nil
    redirect_to admin_sign_in_path
  end

  def recover_password
    if request.post?
      if user = Typus.user_class.find_by_email(params[:user][:email])
        ActionMailer::Base.default_url_options[:host] = request.host_with_port
        TypusMailer.deliver_reset_password_link(user)
        flash[:success] = _("Password recovery link sent to your email.")
        redirect_to admin_sign_in_path
      else
        redirect_to admin_recover_password_path
      end
    end
  end

  ##
  # Available if Typus::Configuration.options[:recover_password] is enabled.
  #
  def reset_password
    @user = Typus.user_class.find_by_token!(params[:token])
    if request.post?
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
      if @user.save
        session[:typus_user_id] = @user.id
        redirect_to admin_dashboard_path
      else
        flash[:error] = _("Passwords don't match.")
        redirect_to admin_reset_password_path(:token => params[:token])
      end
    end
  end

  def sign_up

    redirect_to admin_sign_in_path and return unless Typus.user_class.count.zero?

    if request.post?

      email, password = params[:user][:email], 'columbia'
      user = Typus.user_class.generate(email, password)

      if user.save
        session[:typus_user_id] = user.id
        flash[:notice] = _("Password set to \"{{password}}\".", :password => password)
        redirect_to admin_dashboard_path
      else
        flash[:error] = _("That doesn't seem like a valid email address.")
      end

    else

      flash[:notice] = _("Enter your email below to create the first user.")

    end

  end

private

  def recover_password_disabled?
    redirect_to admin_sign_in_path unless Typus::Configuration.options[:recover_password]
  end

  def select_layout
    [ 'sign_up', 'sign_in', 'sign_out', 'recover_password', 'reset_password' ].include?(action_name) ? 'typus' : 'admin'
  end

end