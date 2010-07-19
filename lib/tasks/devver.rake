require 'rake'

namespace :devver do

  #easy to switch between gem, or old versions of devver
  APP_CALL = 'devver'

  desc "Runs all units functionals and integration tests via devver"
  task :test do
    errors = %w(devver:test:units devver:test:functionals devver:test:integration).collect do |task|
      begin
        Rake::Task[task].invoke
        nil
      rescue => e
        task
      end
    end.compact
    abort "Errors running #{errors.join(", ").to_s}!" if errors.any?
  end

  desc "Forces devver to rerun migration files"
  task :migrate do
    command = "#{APP_CALL} --db"
    puts command
    system(command)
  end

  desc "Forces devver to sync all changed files"
  task :sync do
    command = "#{APP_CALL} --sync"
    puts command
    system(command)
  end
  
  desc "Reset the devver project_id to start fresh"
  task :reset do
    command = "rm .devver/project_id"
    system(command)
    puts "the project has been reset, now feel free to run any devver task to begin working on your new project (example rake devver:test)"
  end
  
  desc "delete all of the project files on the server and resync the project files"
  task :reload do
    command = "#{APP_CALL} --reload"
    puts command
    system(command)
  end

  namespace :test do
    desc "Runs all units tests via devver"
    task :units do
      devvertest('test/unit/**/*_test.rb')
    end

    desc "Runs all functionals tests via devver"
    task :functionals do
      devvertest('test/functional/**/*_test.rb')
    end

    desc "Runs all integration tests via devver"
    task :integration do
      devvertest('test/integration/**/*_test.rb')
    end

  end
end

def devvertest(pattern)
  reload = ENV['reload']=='true' ? true : false
  #default sync to true
  sync = true 
  sync = false if ENV['sync']=='false' 
  cache = ENV['cache']=='true' ? true : false
  db = ENV['db']=='true' ? true : false
  files = FileList[pattern].to_a
  command = "#{APP_CALL} #{'--reload' if reload} #{'--nosync' if !sync} #{'--db' if db} #{'--cache' if cache} #{files.join(' ')}"
  
  puts command
  results = system(command)
  raise RuntimeError.new("Command failed with status (1)") unless results
end
