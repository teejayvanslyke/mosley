module Typus

  class << self

    def version
      @@version ||= File.read("#{path}/VERSION").strip
    end

    def path
      File.dirname(__FILE__) + '/../'
    end

    def locales
      Typus::Configuration.options[:locales]
    end

    def default_locale
      locales.map(&:last).first
    end

    def applications
      Typus::Configuration.config.collect { |i| i.last['application'] }.compact.uniq.sort
    end

    ##
    # Returns a list of the modules of an application.
    #
    def application(name)
      Typus::Configuration.config.collect { |i| i.first if i.last['application'] == name }.compact.uniq.sort
    end

    def models
      Typus::Configuration.config.map { |i| i.first }.sort
    end

    ##
    # Return a list of resources, which are models tableless.
    #
    def resources(models = get_model_names)

      all_resources = Typus::Configuration.roles.keys.map do |key|
                        Typus::Configuration.roles[key].keys
                      end.flatten.sort.uniq

      all_resources.delete_if { |x| models.include?(x) || x == 'TypusUser' } rescue []

    end

    def get_model_names
      Dir[ "#{Rails.root}/app/models/**/*.rb", 
           "#{Rails.root}/vendor/plugins/**/app/models/**/*.rb" ].collect { |m| File.basename(m).sub(/\.rb$/,'').camelize }
    end

    def module_description(modulo)
      Typus::Configuration.config[modulo]['description']
    end

    def user_class
      Typus::Configuration.options[:user_class_name].constantize
    end

    def user_fk
      Typus::Configuration.options[:user_fk]
    end

    def testing?
      Rails.env.test? && Dir.pwd == "#{Rails.root}/vendor/plugins/typus"
    end

    def plugin?
      File.exist?("#{Rails.root}/vendor/plugins/typus")
    end

    ##
    # Enable application. This is used at boot time.
    #
    #   Typus.enable
    #
    def enable

      # Ruby Extensions
      require 'typus/hash'
      require 'typus/object'
      require 'typus/string'

      # Load configuration and roles.
      Typus::Configuration.config!
      Typus::Configuration.roles!

      # Load translation files from the plugin or the gem.
      if plugin?
        I18n.load_path += Dir[File.join("#{Rails.root}/vendor/plugins/typus/config/locales/**/*.{rb,yml}")]
      else
        Gem.path.each { |g| I18n.load_path += Dir[File.join("#{g}/gems/*typus-#{version}/config/locales/**/*.{rb,yml}")] }
      end

      # Require the test/models on when testing.
      require File.dirname(__FILE__) + '/../test/models' if Typus.testing?

      # Rails Extensions.
      require 'typus/active_record'

      # Mixins.
      require 'typus/authentication'
      require 'typus/format'
      require 'typus/generator'
      require 'typus/locale'
      require 'typus/reloader'
      require 'typus/quick_edit'
      require 'typus/user'

      # Vendor.
      require 'vendor/active_record'
      require 'vendor/paginator'

    end

  end

end