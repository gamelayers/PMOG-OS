# From http://railstips.org/2007/3/4/renaming-rhtml-to-erb
# And from http://pastie.org/45061.txt
namespace 'views' do
  desc 'Renames all your rhtml and rxml views to erb'
  task 'rename' do
    Dir.glob('app/views/**/*.rhtml').each do |file|
      puts `svn mv #{file} #{file.gsub(/\.rhtml$/, '.html.erb')}`
    end
    Dir.glob('app/views/**/*.rxml').each do |file|
      puts `svn mv #{file} #{file.gsub(/\.rxml$/, '.xml.erb')}`
    end
  end
end