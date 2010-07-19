Gem::Specification.new do |s|
  s.name = 'acts-as-readable'
  s.version = '1.0.200807042'
  s.date = '2008-07-04'
  
  s.summary = "Makes calling partials in views look better and more fun."
  s.description = "Wrapper around render :partial that removes the need to use :locals, and allows blocks to be taken easily"
  
  s.authors = ['Michael Bleigh']
  s.email = 'michael@intridea.com'
  s.homepage = 'http://github.com/mbleigh/acts-as-readable'
  
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README"]
  s.extra_rdoc_files = ["README"]

  s.add_dependency 'rails', ['>= 2.1']
  
  s.files = ["README",
             "acts-as-readable.gemspec",
             "generators/acts_as_readable_migration/acts_as_readable_migration_generator.rb",
             "generators/acts_as_readable_migration/templates/migration.rb",
             "init.rb",
             "lib/acts-as-readable.rb",
             "lib/reading.rb",
             "lib/user_with_readings.rb",
             "rails/init.rb"]

end

