class Hoarder2BenefactorWithTools < ActiveRecord::Migration
  def self.up
    tool = Tool.find_by_name 'crates'
    tool.character = 'benefactor'
    tool.save
  end

  def self.down
    tool = Tool.find_by_name 'crates'
    tool.character = 'hoarder'
    tool.save
  end
end
