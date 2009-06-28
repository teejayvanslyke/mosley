#############################################################
#	Application
#############################################################

set :application, "teejayvanslykemakesmusic"
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
set :domain, "wobinich.us"
server domain, :app, :web
role :db, domain, :primary => true
role :app, domain, :primary => true
role :web, domain, :asset_host_syncher => true

#############################################################
#	Git
#############################################################

set :scm, :git
set :branch, "master"
set :repository, "git@github.com:teejayvanslyke/musicman.git"
set :deploy_via, :remote_cache


set :mongrel_conf, "#{deploy_to}/current/config/mongrel_cluster.yml"

before "deploy:symlink", "s3_asset_host:synch_public"

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
    
  namespace :mongrel do
    [ :stop, :start, :restart ].each do |t|
      desc "#{t.to_s.capitalize} the mongrel appserver"
      task t, :roles => :app do
        #invoke_command checks the use_sudo variable to determine how to run the mongrel_rails command
        invoke_command "mongrel_rails cluster::#{t.to_s} -C #{mongrel_conf}", :via => run_method
      end
    end
  end

  desc "Custom restart task for mongrel cluster"
  task :restart, :roles => :app, :except => { :no_release => true } do
    deploy.mongrel.restart
  end

  desc "Custom start task for mongrel cluster"
  task :start, :roles => :app do
    deploy.mongrel.start
  end

  desc "Custom stop task for mongrel cluster"
  task :stop, :roles => :app do
    deploy.mongrel.stop
  end

end

namespace :deploy do
  desc "Backup the database and deploy environment to your home directory."
  task :backup do
    filename = "#{deploy_to}/shared/#{Time.now.to_s.gsub(/ /, "_")}.sql.gz"

    on_rollback { run "rm #{filename}" }

    run "mysqldump -u tjvsmm -p teejayvanslykemakesmusic_production | gzip > #{filename}" do |ch, stream, out|
      ch.send_data "zaqwsxcdeRFV\n" if out =~ /^Enter password:/
    end

    `rsync -e ssh -avz #{user}@#{domain}:#{deploy_to}/shared ~/backup/teejayvanslykemakesmusic/`
    run "rm #{filename}"

  end
end
