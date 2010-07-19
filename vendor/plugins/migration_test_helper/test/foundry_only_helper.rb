class Test::Unit::TestCase

  def self.running_in_foundry
    File.expand_path(File.dirname(__FILE__)) =~ /\/rails_plugin_foundry\//
  end

  def running_in_foundry
    self.class.running_in_foundry
  end

  def self.in_foundry_should(behave,&block)
    should(behave,&block) if running_in_foundry
  end

end
