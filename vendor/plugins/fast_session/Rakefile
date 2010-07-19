require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

desc 'Default: run rspec tests.'
task :default => :spec

desc 'Test the fast_sessions plugin.'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib'
  t.pattern = 'spec/*_spec.rb'
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec', '--rails']
end

desc 'Generate documentation for the fast_sessions plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'FastSessions'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/*.rb')
end

