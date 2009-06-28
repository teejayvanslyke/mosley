# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_mosley_session',
  :secret      => '0bf7ae2a709e582c9fcf9be8ed82d5846b465fca7e44f42670f7888029a6fa86bae3f8be874c64479342f2ec8804fce0fcf80d1cbf57e94848066409630affff'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
