class CreateSkeletonKeys < ActiveRecord::Migration
  def self.up
    add_column :tools, :url_name, :string
    Tool.reset_column_information

    # fix all the url names while we're at it
    Tool.all do |t|
      t.url_name = t.name
      t.save
    end

    add_column :inventories, :skeleton_keys, :integer, :limit => 5, :default => 0

    skeleton_keys_data = { :name => "Skeleton Keys",
      :url_name => 'skeleton_keys',
      :classpoints => 5,
      :character => 'seers',
      :icon_image => '/images/shared/icons/skeleton_key-16.png',
      :small_image => '/images/shared/icons/skeleton_key-32.png',
      :medium_image => '/images/shared/icons/skeleton_key-48.png',
      :pmog_class_id => PmogClass.find_by_name("Seers"),
      :short_description => "Unlocks a puzzle crate with a stupid question." }

    create_skeleton_key_data = { :name => "Create Skeleton Key",
      :url_name => 'create_skeleton_key',
      :classpoints => 20,
      :level => 7,
      :ping_cost => 50,
      :pmog_class_id => PmogClass.find_by_name("Seers"),
      :short_description => "Creates a Skeleton Key" }

    @skeleton_keys = Tool.find_by_url_name('skeleton_keys')
    if @skeleton_keys.nil?
      Tool.create(skeleton_keys_data)
    else
      @skeleton_keys.update_attributes(skeleton_keys_data)
    end

    @create_skeleton_key = Ability.find_by_url_name('create_skeleton_key')
    if @create_skeleton_key.nil?
      Ability.create(create_skeleton_key_data)
    else
      @create_skeleton_key.update_attributes(create_skeleton_key_data)
    end
  end

  def self.down
    remove_column :tools, :url_name
    remove_column :inventories, :skeleton_keys
  end
end
