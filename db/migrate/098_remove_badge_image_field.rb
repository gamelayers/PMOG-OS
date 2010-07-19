class RemoveBadgeImageField < ActiveRecord::Migration
  def self.up
    remove_column :badges, :image
    Badge.reset_column_information
  end

  def self.down
    add_column :badges, :image, :string
    Badge.reset_column_information
  end
end
