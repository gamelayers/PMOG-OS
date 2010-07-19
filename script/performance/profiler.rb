# From http://m.onkey.org/2007/10/30/faster-eager-loading-and-funky-joins
# Execute with script/runner script/performance/profiler.rb
#
# Run with script/runner
require 'ruby-prof'
puts "Sanity check..."
puts User.find_with_basics('login', 'suttree').inspect
results = RubyProf.profile { User.find(:all, :include => :portals) }
File.open "#{RAILS_ROOT}/tmp/profile-graph.html", 'w' do |file|
  RubyProf::GraphHtmlPrinter.new(results).print(file)
  `open #{file.path}`
end
