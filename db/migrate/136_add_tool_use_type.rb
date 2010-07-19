class AddToolUseType < ActiveRecord::Migration
  def self.up
    add_column :tool_uses, :type, :string, :default => 'user'
  end

  def self.down
    remove_column :tool_uses, :type
  end
end
