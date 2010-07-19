namespace :cerberus do
  desc 'Setup database.yml'
  task :setup do
    system("cp ~/src/pmog/trunk/config/database.yml #{RAILS_ROOT}/config/database.yml")
  end 
end