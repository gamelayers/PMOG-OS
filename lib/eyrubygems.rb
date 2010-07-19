$:.unshift File.dirname(__FILE__)

module Kernel
  # Same as the +gem+ command, but will also require a file if the gem
  # provides an auto-required file name.
  #
  # DEPRECATED!  Use +gem+ instead.
  #
  def require_gem(gem_name, *version_requirements)
    file, lineno = location_of_caller
    warn "#{file}:#{lineno}:Warning: require_gem is obsolete.  Use the 'gem' method instead, and contact the gem author about updating this gem."
    active_gem_with_options(gem_name, version_requirements, :auto_require=>true)
  end
end