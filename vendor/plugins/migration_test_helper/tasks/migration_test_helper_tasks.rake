
namespace :test do

  Rake::TestTask.new(:migrations => "db:test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'test/migration/**/*_test.rb'
    t.verbose = true
  end
  Rake::Task['test:migrations'].comment = "Run the migration tests in test/migration"

  task :migration => 'test:migrations'
end

task :test do
  Rake::Task['test:migrations'].invoke rescue got_error = true
  raise "Test failures" if got_error
end
