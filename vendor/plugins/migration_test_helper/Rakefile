require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'hoe'

desc 'Default: run unit tests.'
task :default => :test

desc 'Generate documentation for the migration_test_helper plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'MigrationTestHelper'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

GEM_VERSION = '1.3.3'

Hoe.new('migration_test_helper',GEM_VERSION) do |p|
  p.author = "Micah Alles" 
  p.email = "micah@atomicobject.com" 
  p.url = "http://migrationtest.rubyforge.org" 
  p.summary = "A Rails plugin for testing migrations" 
  p.description = <<-EOS
migration_test_helper makes testing your migrations easier by 
adding helper methods to Test::Unit::TestCase for asserting the 
current state of the schema and executing migrations against the 
test database.
  EOS

  p.changes = <<-EOS
* fixed bug where test:migration was calling itself, thanks Patrick ;)
  EOS
  p.rubyforge_name = 'migrationtest'
end

desc "Generate and upload api docs to rubyforge"
task :upload_doc => :rerdoc do
  sh "scp -r rdoc/* rubyforge.org:/var/www/gforge-projects/migrationtest/"
end

desc "Release from current trunk"
task :plugin_release do
	require 'fileutils'
	include FileUtils::Verbose
  cd File.expand_path(File.dirname(__FILE__)) do
    sh 'svn up'
    status = `svn status` 
    raise "Please clean up before releasing.\n#{status}" unless status == ""

    unless `svn ls svn+ssh://alles@rubyforge.org/var/svn/migrationtest/tags/rel-#{GEM_VERSION} -m`.strip.empty?
      sh "svn del svn+ssh://alles@rubyforge.org/var/svn/migrationtest/tags/rel-#{GEM_VERSION} -m 'Preparing to update stable release tag'"
    end
    sh "svn cp . svn+ssh://alles@rubyforge.org/var/svn/migrationtest/tags/rel-#{GEM_VERSION} -m 'Releasing version #{GEM_VERSION}'"
    unless `svn ls svn+ssh://alles@rubyforge.org/var/svn/migrationtest/tags/migration_test_helper`.strip.empty?
      sh "svn del svn+ssh://alles@rubyforge.org/var/svn/migrationtest/tags/migration_test_helper -m 'Preparing to update stable release tag'"
    end
    sh "svn cp . svn+ssh://alles@rubyforge.org/var/svn/migrationtest/tags/migration_test_helper -m 'Updating stable tag to version #{GEM_VERSION}'"
  end
end
