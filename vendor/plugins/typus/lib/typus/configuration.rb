module Typus

  module Configuration

    ##
    # Default Typus options which can be overwritten from the 
    # initializer. Example:
    #
    #     Typus::Configuration.options[:recover_password]
    #
    # Special cases:
    #
    #     Typus::Configuration.options[:user_fk]
    #     Typus.user_fk
    #
    #     Typus::Configuration.options[:user_class_name]
    #     Typus.user_class
    #
    typus_options = { :app_name => 'Typus', 
                      :config_folder => 'config/typus', 
                      :email => 'admin@example.com', 
                      :locales => [ [ "English", :en ] ], 
                      :recover_password => false, 
                      :root => 'admin', 
                      :ssl => false, 
                      :templates_folder => 'admin/templates',
                      :user_class_name => 'TypusUser', 
                      :user_fk => 'typus_user_id' }

    ##
    # Default model options which can be overwritten from the 
    # initializer. Example:
    #
    #    Model.typus_options_for(:default_action_on_item)
    #
    model_options = { :default_action_on_item => 'edit', 
                      :end_year => nil,
                      :form_rows => 10, 
                      :icon_on_boolean => true, 
                      :index_after_save => false, 
                      :minute_step => 5, 
                      :nil => 'nil', 
                      :only_user_items => false, 
                      :per_page => 15, 
                      :sidebar_selector => 5, 
                      :start_year => nil, 
                      :toggle => true }

    @@options = typus_options.merge(model_options)

    mattr_accessor :options

    ##
    # Read Typus Configuration files placed on <tt>config/typus/**/*.yml</tt>.
    #
    #   Typus::Configuration.config! overwrites @@config
    #
    def self.config!

      files = Dir["#{Rails.root}/#{options[:config_folder]}/**/*.yml"].sort
      files = files.delete_if { |x| x.include?('_roles.yml') }

      @@config = {}
      files.each do |file|
        data = YAML.load_file(file)
        @@config = @@config.merge(data) if data
      end

      return @@config

    end

    mattr_accessor :config

    ##
    # Read Typus Roles from configuration files placed on <tt>config/typus/**/*_roles.yml</tt>.
    #
    #   Typus::Configuration.roles! overwrites @@roles
    #
    def self.roles!

      files = Dir["#{Rails.root}/#{options[:config_folder]}/**/*_roles.yml"].sort

      @@roles = { options[:root] => {} }

      files.each do |file|
        data = YAML.load_file(file)
        next unless data
        data.each do |key, value|
          next unless value
          begin
            @@roles[key] = @@roles[key].merge(value)
          rescue
            @@roles[key] = value
          end
        end
      end

      return @@roles.compact

    end

    mattr_accessor :roles

  end

end