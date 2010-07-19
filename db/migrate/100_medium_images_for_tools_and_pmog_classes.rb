class MediumImagesForToolsAndPmogClasses < ActiveRecord::Migration
  # Ticket #233 and #238. Adding medium and icon image sizes to the database for tools and pmog_classes
  # Also changing the large images to .png, the rest are .jpg
  
  # Ticket #237. Making the association names all plural.
  def self.up
    add_column :tools, :medium_image, :string, :limit => 255, :null => false
    add_column :tools, :icon_image, :string, :limit => 255, :null => false
    
    add_column :pmog_classes, :medium_image, :string, :limit => 255, :null => false
    add_column :pmog_classes, :icon_image, :string, :limit => 255, :null => false
    
    Tool.find(:all).each do |tool|
      tool.large_image = "/images/shared/tools/large/" + tool.name.downcase + ".png"
      tool.medium_image = "/images/shared/tools/medium/" + tool.name.downcase + ".jpg"
      tool.icon_image = "/images/shared/tools/icon/" + tool.name.downcase + ".jpg"
      tool.save
    end

    [ 'Benefactor', 'Seer', 'Shoat' ].each do |assoc|
      pmog_class = PmogClass.find( :first, :conditions => { :name => assoc } )
      
      unless pmog_class.nil?
        pmog_class.name = assoc.pluralize
        pmog_class.save
      end
    end

    PmogClass.find(:all).each do |pmog_class|
      pmog_class.large_image = "/images/shared/associations/large/" + pmog_class.name.downcase + ".png"
      pmog_class.medium_image = "/images/shared/associations/medium/" + pmog_class.name.downcase + ".jpg"
      pmog_class.icon_image = "/images/shared/associations/icon/" + pmog_class.name.downcase + ".jpg"
      pmog_class.save
    end
  end

  def self.down
    remove_column :tools, :medium_image
    remove_column :tools, :icon_image

    remove_column :pmog_classes, :medium_image
    remove_column :pmog_classes, :icon_image

    [ 'Benefactors', 'Seers', 'Shoats' ].each do |assoc|
      pmog_class = PmogClass.find( :first, :conditions => { :name => assoc} )

      unless pmog_class.nil?
        pmog_class.name = assoc.singularize
        pmog_class.save
      end
    end

  end
end
