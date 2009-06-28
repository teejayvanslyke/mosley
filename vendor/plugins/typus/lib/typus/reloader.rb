module Typus

  module Reloader

    ##
    # Reload config and roles when app is running in development.
    #
    def reload_config_et_roles
      return if Rails.env.production?
      logger.info "=> [typus] Configuration files have been reloaded."
      Typus::Configuration.roles!
      Typus::Configuration.config!
    end

  end

end