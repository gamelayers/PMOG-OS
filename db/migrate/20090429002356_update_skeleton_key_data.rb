class UpdateSkeletonKeyData < ActiveRecord::Migration
  def self.up
    @skeleton_key = Tool.find_by_url_name('skeleton_keys')
    @skeleton_key.update_attributes(:classpoints => 0)
  end

  def self.down
  end
end
