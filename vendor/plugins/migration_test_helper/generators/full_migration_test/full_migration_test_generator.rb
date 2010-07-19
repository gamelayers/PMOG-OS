class FullMigrationTestGenerator < Rails::Generator::Base
  def manifest
    record do |m|

      m.directory 'test/migration'
      m.template 'full_migration_test.rb',
                 'test/migration/full_migration_test.rb'
    end
  end
end
