class AddUrlNameToPmogClasses < ActiveRecord::Migration
  def self.up
    add_column :pmog_classes, :url_name, :string

    PmogClass.reset_column_information

    PmogClass.all do |c|
      c.url_name = c.name.singularize.downcase
      c.save
    end
  end

  def self.down
    remove_column :pmog_classes, :url_name
  end
end
