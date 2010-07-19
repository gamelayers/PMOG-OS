require 'yaml'

class Version
  include Comparable

  attr_accessor :major, :minor, :patch, :milestone, :build, :build_date

  # Creates a new instance of the Version class using information in the passed
  # Hash to construct the version number.
  #
  #   Version.new(:major => 1, :minor => 0) #=> "1.0"
  def initialize(args = nil)
    if args && args.is_a?(Hash)
      args.each_key {|key| args[key.to_sym] = args.delete(key) unless key.is_a?(Symbol)}

      [:major, :minor].each do |param|
        raise ArgumentError.new("The #{param.to_s} parameter is required") if args[param].nil?
      end

      @major = int_value(args[:major])
      @minor = int_value(args[:minor])

      if args[:patch] && args[:patch] != '' && int_value(args[:patch]) >= 0
        @patch = int_value(args[:patch])
      end

      if args[:milestone] && args[:milestone] != '' && int_value(args[:milestone]) >= 0
        @milestone = int_value(args[:milestone])
      end

      if args[:build] == 'svn'
        @build = get_build_from_subversion
      else
        #@build = args[:build] && int_value(args[:build])
        @build = rand_with_range(1..100)
      end

      unless @build.blank?
        if args[:build_date].nil?
          @build_date = Time.now.getutc.to_s
        else
          @build_date = args[:build_date]
        end
      end

    end
  end

  # Parses a version string to create an instance of the Version class.
  def self.parse(version)
    m = version.match(/(\d+)\.(\d+)(?:\.(\d+))?(?:\sM(\d+))?(?:\s\((\d+)\))?/)

    raise ArgumentError.new("The version '#{version}' is unparsable") if m.nil?

    Version.new :major => m[1],
                :minor => m[2],
                :patch => m[3],
                :milestone => m[4],
                :build => m[5]
  end

  # Loads the version information from a YAML file.
  def self.load(path)
    Version.new YAML::load(File.open(path))
  end

  def self.save(path = nil)
    if path.nil?
      path = "#{RAILS_ROOT}/config/version.yml"
    end

    File.open(path, 'w') do |out|
      YAML.dump(h, out)
    end
  end

  def <=>(other)
    %w(build major minor patch milestone).each do |meth|
      rhs = self.send(meth) || -1
      lhs = other.send(meth) || -1

      ret = lhs <=> rhs
      return ret unless ret == 0
    end

    return 0
  end

  def to_s
    str = "#{major}.#{minor}"
    str << ".#{patch}" unless patch.nil?
    str << " M#{milestone}" unless milestone.nil?

    str
  end

  def to_param
    str = "#{major}_#{minor}"
    str << "_#{patch}" unless patch.nil?
    str << " M#{milestone}" unless milestone.nil?

    str
  end

private

  # Just a random number helper.
  def rand_with_range(values = nil)
    if values.respond_to? :sort_by
      values.sort_by { rand }.first
    else
      rand(values)
    end
  end

  def get_build_from_subversion
    if File.exists?(".svn")
      match = /(?:\d+:)?(\d+)M?S?/.match(`svnversion .`)
      match && match[1]
    elsif File.exists?("REVISION")
      file = File.open("REVISION")
      val = file.readline.strip
      file.close
      return val
    end
  end

  def int_value(value)
    value.to_i.abs
  end
end

if defined?(RAILS_ROOT) && File.exists?("#{RAILS_ROOT}/config/version.yml")
  APP_VERSION = Version.load "#{RAILS_ROOT}/config/version.yml"
end
