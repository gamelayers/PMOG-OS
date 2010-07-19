class ActsAsSubscribeableInstallationGenerator < Rails::Generator::NamedBase  
  def initialize(runtime_args, runtime_options)
    super(["create_acts_as_subscribeable_tables"], runtime_options)
  end
  
  def manifest
    record do |m|
      m.directory File.join('config/', "initializers")
      m.template 'mailer.rb', "config/initializers/mailer.rb"
      
      m.migration_template 'acts_as_subscribeable_migration.rb', 'db/migrate'
    end
  end
end
