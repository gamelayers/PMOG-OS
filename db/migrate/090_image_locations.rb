class ImageLocations < ActiveRecord::Migration
  def self.up
    Tool.find(:all).each do |tool|
      tool.small_image = "/images/shared/tools/small/#{tool.name.singularize.downcase}.jpg"
      tool.large_image = "/images/shared/tools/large/#{tool.name.singularize.downcase}.jpg"
      tool.save
    end
    
    st_nick = Tool.find_by_name( 'st_nicks' )
    st_nick.small_image = "/images/shared/tools/small/stnick.jpg"
    st_nick.large_image = "/images/shared/tools/large/stnick.jpg"
    st_nick.save
    
    PmogClass.find(:all).each do |pmog_class|
      pmog_class.small_image = "/images/shared/associations/small/#{pmog_class.name.singularize.downcase}.jpg"
      pmog_class.large_image = "/images/shared/associations/large/#{pmog_class.name.singularize.downcase}.jpg"
      pmog_class.save
    end
  end

  def self.down
    # n/a
  end
end
