# new 16 pixel icon designations
class AssociationAndToolImagesChange < ActiveRecord::Migration
  def self.up
    Tool.find(:all).each do |tool|
      tool.small_image = "/images/shared/tools/small/" + tool.name.downcase.pluralize + ".jpg"
      tool.medium_image = "/images/shared/tools/medium/" + tool.name.downcase.pluralize + ".jpg"
      tool.large_image = "/images/shared/tools/large/" + tool.name.downcase.pluralize + ".png"
      tool.icon_image = "/images/shared/tools/icon/" + tool.name.downcase.singularize + "-16.png"
      tool.save
    end

    PmogClass.find(:all).each do |pmog_class|
      pmog_class.small_image = "/images/shared/associations/small/" + pmog_class.name.downcase.pluralize + ".jpg"
      pmog_class.medium_image = "/images/shared/associations/medium/" + pmog_class.name.downcase.pluralize + ".jpg"
      pmog_class.large_image = "/images/shared/associations/large/" + pmog_class.name.downcase.pluralize + ".png"
      pmog_class.icon_image = "/images/shared/associations/icon/" + pmog_class.name.downcase.singularize + "-16.png"
      pmog_class.save
    end

  end
end