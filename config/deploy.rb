#############################################################
#	Application
#############################################################

set :application, "kelseymosley"
set :deploy_to, "/var/www/#{application}"

#############################################################
#	Settings
#############################################################

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
set :use_sudo, true
set :scm_verbose, true
set :rails_env, "production" 

#############################################################
#	Servers
#############################################################

set :user, "deploy"
set :domain, "tjvanslyke.com"
server domain, :app, :web
role :db, domain, :primary => true
role :app, domain, :primary => true
role :web, domain, :asset_host_syncher => true

#############################################################
#	Git
#############################################################

set :scm, :git
set :branch, "master"
set :repository, "git@github.com:teejayvanslyke/mosley.git"
set :deploy_via, :remote_cache

namespace :deploy do
  desc "Create the database yaml file"
  task :after_update_code do
    db_config = <<-EOF
    production:    
      adapter: mysql
      encoding: utf8
      username: tjvsmm
      password: zaqwsxcdeRFV
      database: teejayvanslykemakesmusic_production
      host: localhost
      port: 3306
    EOF
    
    put db_config, "#{release_path}/config/database.yml"
    
    #########################################################
    # Uncomment the following to symlink an uploads directory.
    # Just change the paths to whatever you need.
    #########################################################
    

    def symlink_public_directory(name)
      run "mkdir -p #{shared_path}/#{name}"
      run "ln -s #{shared_path}/#{name} #{release_path}/public/#{name}"
    end

    desc "Symlink the upload directories"
    task :before_symlink do
      symlink_public_directory 'background_images'
      symlink_public_directory 'audios'
    end
  
  end

  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    delayed_job.stop
    run "touch #{current_path}/tmp/restart.txt"
    delayed_job.start
  end
  
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
    
end

