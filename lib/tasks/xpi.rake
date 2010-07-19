# = Pmog XPI Tasks
#
# Author::    Mark Daggett
#
#
# = Synopsis
#
#  from the CommandLine within your RubyOnRails application folder
#  $ rake -T
#    rake pmog:xpi:hud                   # Package a new version of the PMOG hud that players install
#    rake pmog:xpi:hud_admin             # Package a new version of the PMOG admin extension, which installs into the player's hud.
#    rake pmog:xpi                       # Package all extensions into their respective xpi files.
#    rake pmog:xpi:stage                 # Prepare the newly created file for deployment.
#    rake pmog:xpi:localize              # Update the local install of all extensions to point to the current branch.
#    rake pmog:xpi:localize:hud          # Update the local install of the pmog extension to point to the current branch.
#    rake pmog:xpi:localize:hud_admin    # Update the local install of the pmog extension to point to the current branch.
#
#  By default javascript files are compressed as part of the extension build process. To build an extension without
#  compression call the rake task like so:
#
#  rake pmog:xpi:hud uncompressed=true
# = Description
#
#  There are a few prerequisites to get this up and running:
#    * This rake tasks assumes you are using SVN as a SCM. It will try and export the extensions first into a build folder
#      before attempting to make a package.

# = Credits and License
#
#  Written for Gamelayers by Mark Daggett from Locus Focus.
#
#  Copyright 2008 Gamelayers all rights reserved.
#
#
require 'yaml'
require 'erb'
require 'tempfile'
require 'find'
namespace :pmog do
  desc 'Package all available extensions into their respective xpi files.'
  task :xpi => [ "pmog:xpi:hud", "pmog:xpi:pmog_chat", "pmog:xpi:installer"]

  namespace :xpi do
    desc 'Package the Pmog extension code as an xpi file.'
    task :hud do
      load_yml
      puts "Building the Pmog hud extension."
      configure_and_build('hud')
    end

    desc 'Package the Pmog admin extension as an xpi file.'
    task :hud_admin do
      load_yml
      puts "Building the Pmog admin extension."
      configure_and_build('hud_admin')
    end

    desc 'Package the Pmog Chat extension as an xpi file.'
    task :pmog_chat do
      load_yml
      puts "Building the Pmog chat extension."
      configure_and_build('pmog_chat')
    end

    desc 'Make the multiple item installer'
    task :merge do
      load_yml
      puts "Merging extensions"
      build_combined()
    end

    desc 'Make the multiple item installer'
    task :installer do
      load_yml
      puts "Building the multiple item installer"
      make_installer()
    end

    desc 'Stage the xpi file and update.rdf file in trunk.'
    task :stage do
      load_yml
      edit_rdf(@config['update_rdf']['source_folder'], @config['hud']['version'])
      system "cp #{RAILS_ROOT}/pmog.xpi #{RAILS_ROOT}/public/xpi/"
      puts "Everything has been staged for deployment."
    end

    desc 'Update the symlink targets for all extensions'
    task :localize => ["pmog:xpi:localize:hud", "pmog:xpi:localize:hud_admin"]

    namespace :localize do
      desc 'Update the symlink target for the local install to the hud'
      task :hud do
        localize_extension('hud')
      end

      desc 'Update the symlink target for the local install to the admin'
      task :hud_admin do
        localize_extension('hud_admin')
      end
    end
  end
end

private

def configure_and_build(name)
  build_extension({:export_folder => @config[name]['export_folder'],
                   :source_folder => @config[name]['source_folder'],
                   :uid           => @config[name]['uid'],
                   :name          => @config[name]['name'],
                   :version       => @config[name]['version'],
                   :description   => @config[name]['description']})
end

def load_yml
  @config ||= YAML::load(ERB.new(IO.read("#{RAILS_ROOT}/config/xpi.yml")).result)
  @developer_config ||= YAML::load(ERB.new(IO.read("#{RAILS_ROOT}/config/developer.yml")).result)
end

# Converts the chrome manifest file from a flat directory structure to one expecting jar files.
def jar_chrome_manifest(chrome_file, name)
  chrome_file.strip!
  if File.exists?(chrome_file)
    File.open(chrome_file, 'r+') do |f|   # open file for update
        lines = f.readlines               # read into array of lines
        lines.each do |chrome|            # modify lines
          chrome.gsub!("chrome", 'jar:chrome') unless chrome.match("overlay")
          chrome.gsub!("chrome/","chrome/#{name}.jar!/")
        end
        f.pos = 0                        # back to start
        f.print lines                    # write out modified lines
        f.truncate(f.pos)                # truncate to new length
    end                                  # file is automatically closed
  else
    puts "ERROR: Could not find chrome.manifest file here: #{chrome_file}"
  end
end

def edit_rdf(rdf_file, version, description=nil)
  rdf_file.strip!
  if File.exists?(rdf_file)
    File.open(rdf_file, 'r+') do |f|  # open file for update
        lines = f.readlines           # read into array of lines
        lines.each do |line|          # modify lines
          line.gsub!(/<em:version>.*<\/em:version>/,"<em:version>#{version}</em:version>")
          line.gsub!(/<em:description>.*<\/em:description>/,"<em:description>#{description unless description.nil?} build: #{Time.now.strftime("%y-%j-%H")}</em:description>")
        end

        f.pos = 0                     # back to start
        f.print lines                 # write out modified lines
        f.truncate(f.pos)             # truncate to new length
    end                               # file is automatically closed
  else
    puts "ERROR: Could not find chrome.manifest file here: #{chrome_file}"
  end

end

def update_css_version_number(path, version)
  path.strip!
  file = "#{path}/pmog\@gamelayers.com/chrome/skin/pmog.css"
  if File.exists?(file)
    new_css_style = "#pmog_version { list-style-image: url('chrome://pmog/skin/icons/plain/p-12.png'); margin: #{version.split('.')[0]}px #{version.split('.')[1]}px 0px 0px !important; display:none !important;}"
    File.open(file, 'r+') do |f|  # open file for update
      lines = f.readlines           # read into array of lines
      lines.each do |line|          # modify lines
        line.gsub!(/#pmog_version .*}/, new_css_style)
      end
      f.pos = 0                     # back to start
      f.print lines                 # write out modified lines
      f.truncate(f.pos)             # truncate to new length
                                    # file is automatically closed
    end
  else
    puts "ERROR: Could not find the css file at this location: #{file}."
  end
end

def build_extension(params ={})
  opts = {:export_folder => '', :source_folder => '', :uid => '', :name => ''}.merge(params)
  opts.each_pair do |k,v|
    raise "ERROR: Missing required arguments, \"#{k}\" was blank." if opts[k][v].blank?
  end

  system "cp -R #{opts[:source_folder]} #{opts[:export_folder]}"

  # The hud now has a CSS file that needs to be updated each time the extension is packaged.
  # This we place the version of the extension into the css file so that we can get access to it
  # using JS.
  #update_css_version_number("#{opts[:export_folder]}", opts[:version]) if opts[:name] == 'pmog'

  system "mkdir  #{opts[:export_folder]}/build/"
  system "mkdir  #{opts[:export_folder]}/build/chrome"
  minify("#{opts[:export_folder]}/#{opts[:uid]}/chrome/content/javascript") unless ENV.include?("uncompressed")
  Dir.chdir("#{opts[:export_folder]}/#{opts[:uid]}/chrome") do
    puts "Adding #{opts[:name]}"
    system "zip -rq #{opts[:name]}.jar *"
  end

  system "mv #{opts[:export_folder]}/#{opts[:uid]}/chrome/#{opts[:name]}.jar #{opts[:export_folder]}/build/chrome/#{opts[:name]}.jar"
  system "cp -R  #{opts[:export_folder]}/#{opts[:uid]}/defaults #{opts[:export_folder]}/build/"
  system "cp -R  #{opts[:export_folder]}/#{opts[:uid]}/platform #{opts[:export_folder]}/build/"
  system "cp -R  #{opts[:export_folder]}/#{opts[:uid]}/install.rdf #{opts[:export_folder]}/build/install.rdf"
  edit_rdf("#{opts[:export_folder]}/build/install.rdf", opts[:version], opts[:description])
  system "cp -R  #{opts[:export_folder]}/#{opts[:uid]}/chrome.manifest #{opts[:export_folder]}/build/chrome.manifest"
  jar_chrome_manifest("#{opts[:export_folder]}/build/chrome.manifest", opts[:name])
  Dir.chdir("#{opts[:export_folder]}/build/") do
    system "zip -rq #{opts[:name]}.xpi *"
  end

  system "mv #{opts[:export_folder]}/build/#{opts[:name]}.xpi #{RAILS_ROOT}/xpi/#{opts[:name]}.xpi"
  system "rm -rf #{opts[:export_folder]}"
  puts "Extension built successfully and has been placed here: #{RAILS_ROOT}/xpi/#{opts[:name]}.xpi ."
end

def build_combined()

  merge_path = "#{RAILS_ROOT}/xpi/merge"
  chrome_path = "#{merge_path}/chrome"
  dist_path = "#{RAILS_ROOT}/public/xpi"

  system "mkdir #{chrome_path}"

  system "cp -R #{RAILS_ROOT}/../pmog-hud/pmog@gamelayers.com #{chrome_path}"
  #system "cp -R #{RAILS_ROOT}/../pmog-chat/pmog_chat@gamelayers.com #{chrome_path}"

  #system "rm #{chrome_path}/pmog_chat@gamelayers.com/chrome.manifest"
  #system "rm #{chrome_path}/pmog_chat@gamelayers.com/install.rdf"

  system "rm #{chrome_path}/pmog@gamelayers.com/chrome.manifest"
  system "rm #{chrome_path}/pmog@gamelayers.com/install.rdf"

  system "mkdir #{merge_path}/defaults"
  system "mkdir #{merge_path}/defaults/preferences"

  system "cp #{chrome_path}/pmog@gamelayers.com/defaults/preferences/pmog.js #{merge_path}/defaults/preferences"
  #system "cp #{chrome_path}/pmog_chat@gamelayers.com/defaults/preferences/pmog_chat.js #{merge_path}/defaults/preferences"

  #system "rm -Rf #{chrome_path}/pmog_chat@gamelayers.com/defaults"
  system "rm -Rf #{chrome_path}/pmog@gamelayers.com/defaults"

  system "mkdir #{merge_path}/platform"
  system "mkdir #{merge_path}/platform/Darwin"
  system "mkdir #{merge_path}/platform/Linux"

  system "cp -R #{chrome_path}/pmog@gamelayers.com/modules #{merge_path}"

  darwin_manifest = File.open("#{merge_path}/platform/Darwin/chrome.manifest", "a") do |file|
    # IO.foreach("#{chrome_path}/pmog_chat@gamelayers.com/platform/Darwin/chrome.manifest") do |line|
    #   file.puts line
    # end

    IO.foreach("#{chrome_path}/pmog@gamelayers.com/platform/Darwin/chrome.manifest") do |line|
      file.puts line
    end
  end

  linux_manifest = File.open("#{merge_path}/platform/Linux/chrome.manifest", "a") do |file|
    IO.foreach("#{chrome_path}/pmog@gamelayers.com/platform/Linux/chrome.manifest") do |line|
      file.puts line
    end
  end

  #system "cp -R #{chrome_path}/pmog_chat@gamelayers.com/platform #{merge_path}"
  # system "rm -Rf #{chrome_path}/pmog_chat@gamelayers.com/platform"
  system "rm -Rf #{chrome_path}/pmog@gamelayers.com/platform"

  minify("#{chrome_path}/pmog@gamelayers.com/chrome/content/javascript")
  #minify("#{chrome_path}/pmog_chat@gamelayers.com/chrome/content/javascript")
  #minify("#{chrome_path}/pmog_chat@gamelayers.com/chrome/content/lib")
  #minify("#{chrome_path}/pmog_chat@gamelayers.com/chrome/content/utils")

  Dir.chdir("#{chrome_path}") do
    puts "Creating pmog.jar"
    system "zip -rq pmog.jar *"
  end

  system "mv #{chrome_path}/pmog.jar #{merge_path}"

  system "rm -Rf #{chrome_path}"

  edit_rdf("#{merge_path}/install.rdf", @config['hud']['version'], @config['hud']['description'])

  Dir.chdir("#{merge_path}") do
    system "zip -rq pmog.xpi *"
  end

  system "mkdir #{merge_path}/dist"
  system "mv #{merge_path}/pmog.xpi #{merge_path}/dist"
  system "cp #{merge_path}/dist/pmog.xpi #{dist_path}"
  system "cp #{merge_path}/dist/pmog.xpi #{dist_path}/#{@config['hud']['name']}-#{@config['hud']['version']}.xpi"

  system "rm -Rf #{merge_path}/pmog@gamelayers.com"
  #system "rm -Rf #{merge_path}/pmog_chat@gamelayers.com"
  system "rm -Rf #{merge_path}/defaults"
  system "rm -Rf #{merge_path}/platform"
  system "rm -Rf #{merge_path}/modules"
  system "rm -f #{merge_path}/pmog.jar"
  system "rm -Rf #{merge_path}/dist"
end

def make_installer
  puts "Building the multiple item install xpi..."
  Dir.chdir("#{RAILS_ROOT}/xpi/") do
    system "zip -rq  pmog_installer.xpi *"
  end
end

def minify(dir)
  original_size = calculate_directory_size(dir)
  puts "---"
  puts "Minimizing Javascript"
  puts "Original Size: #{number_to_human_size(original_size)}"

  # Change directories to the javascript files
  pwd = Dir.pwd
  Dir.chdir(dir)

  # Only compress Javascript Files
  libs = Dir.glob("*.{js}")
  jsmin = "#{RAILS_ROOT}/lib/jsmin.rb"
  # minify file
  libs.each do |file|
    tmp = Tempfile.open('all')
    open(file) { |f| tmp.write(f.read) }
    tmp.rewind
    %x[ruby #{jsmin} < #{tmp.path} > #{dir}/#{file}]
  end
  new_size = calculate_directory_size(dir)
  puts "Compressed Size: #{number_to_human_size(new_size)}"
  puts "Compression Savings: #{(100 * (Kernel.Float(new_size) / Kernel.Float(original_size))).to_i}%"
  # change back to the previous directory
  Dir.chdir(pwd)
end

def calculate_directory_size(dir)
  dirsize = 0
  Find.find(dir) do |f| dirsize += File.stat(f).size end
  dirsize
end

def number_to_human_size(size, precision=1)
  size = Kernel.Float(size)
  case
    when size.to_i == 1;    "1 Byte"
    when size < 1.kilobyte; "%d Bytes" % size
    when size < 1.megabyte; "%.#{precision}f KB"  % (size / 1.0.kilobyte)
    when size < 1.gigabyte; "%.#{precision}f MB"  % (size / 1.0.megabyte)
    when size < 1.terabyte; "%.#{precision}f GB"  % (size / 1.0.gigabyte)
    else                    "%.#{precision}f TB"  % (size / 1.0.terabyte)
  end.sub(/([0-9]\.\d*?)0+ /, '\1 ' ).sub(/\. /,' ')
rescue
  nil
end

def localize_extension(name)
  load_yml
  update_local_install_path(@developer_config['update_local_install']['extensions_folder'], @config[name])
  puts "---"
  puts "The local install of the #{name} now points to #{RAILS_ROOT}."
  puts "Make sure to restart Firefox!"
end

def update_local_install_path(path = {}, extension = {})
  path.strip!
  file = "#{path}#{extension['uid']}"
  #if File.exists?(file)
  if File.exists?(file) and File.directory?(file)
    puts "ERROR: Could not find the extension folder at this location: #{file}."                                    # file is automatically closed
  else
    File.open(file, 'w+') do |f|  # open file for update
      lines = f.readlines           # read into array of lines
      lines[0] = "#{extension['source_folder']}/#{extension['uid']}"
      f.pos = 0                     # back to start
      f.print lines                 # write out modified lines
      f.truncate(f.pos)             # truncate to new length
    end

  end
end