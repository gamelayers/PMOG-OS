namespace :app do
  desc 'Report the application version.'
  task :version do
    require File.join(File.dirname(__FILE__), "../lib/app_version.rb")
    puts "Application version: " << Version.load("#{RAILS_ROOT}/config/version.yml").to_s
  end
end
