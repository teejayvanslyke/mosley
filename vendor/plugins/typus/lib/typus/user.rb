module Typus

  module EnableAsTypusUser

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def enable_as_typus_user

        extend ClassMethodsMixin

        attr_accessor :password

        validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/
        validates_presence_of :email
        validates_uniqueness_of :email

        validates_confirmation_of :password, :if => :password_required?
        validates_length_of :password, :within => 8..40, :if => :password_required?
        validates_presence_of :password, :if => :password_required?

        validates_presence_of :role

        before_save :initialize_salt, :encrypt_password, :initialize_token

        include InstanceMethods

      end

    end

    module ClassMethodsMixin

      def role
        Typus::Configuration.roles.keys.sort
      end

      def authenticate(email, password)
        user = find_by_email_and_status(email, true)
        user && user.authenticated?(password) ? user : nil
      end

      def generate(email, password, role = Typus::Configuration.options[:root], status = true)
        new :email => email, 
            :password => password, 
            :password_confirmation => password, 
            :role => role, 
            :status => status
      end

    end

    module InstanceMethods

      def name
        (!first_name.empty? && !last_name.empty?) ? "#{first_name} #{last_name}" : email
      end

     def authenticated?(password)
        crypted_password == encrypt(password)
      end

      def resources
        Typus::Configuration.roles[role].compact
      end

      def can_perform?(resource, action, options = {})

        if options[:special]
          _action = action
        else
          _action = case action
                    when 'new', 'create':       'create'
                    when 'index', 'show':       'read'
                    when 'edit', 'update':      'update'
                    when 'position':            'update'
                    when 'toggle':              'update'
                    when 'relate', 'unrelate':  'update'
                    when 'destroy':             'delete'
                    else
                      action
                    end
        end

        # OPTIMIZE: We should not use a rescue.
        resources[resource.to_s].split(', ').include?(_action) rescue false

      end

      def is_root?
        role == Typus::Configuration.options[:root]
      end

    protected

      def generate_hash(string)
        Digest::SHA1.hexdigest(string)
      end

      def encrypt_password
        return if password.blank?
        self.crypted_password = encrypt(password)
      end

      def encrypt(string)
        generate_hash("--#{salt}--#{string}")
      end

      def initialize_salt
        self.salt = generate_hash("--#{Time.now.utc.to_s}--#{email}--") if new_record?
      end

      def initialize_token
        generate_token if new_record?
      end

      def generate_token
        self.token = encrypt("--#{Time.now.utc.to_s}--#{password}--").first(12)
      end

      def password_required?
        crypted_password.blank? || !password.blank?
      end

    end

  end

end

ActiveRecord::Base.send :include, Typus::EnableAsTypusUser