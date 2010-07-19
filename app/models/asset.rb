# == Schema Information
# Schema version: 20081220201004
#
# Table name: assets
#
#  id              :string(36)    primary key
#  filename        :string(255)   
#  width           :integer(11)   
#  height          :integer(11)   
#  content_type    :string(255)   
#  size            :integer(11)   
#  attachable_type :string(255)   
#  attachable_id   :string(36)    
#  updated_at      :datetime      
#  created_at      :datetime      
#  thumbnail       :string(255)   
#  parent_id       :string(36)    
#  crop_x1         :integer(11)   
#  crop_y1         :integer(11)   
#  crop_x2         :integer(11)   
#  crop_y2         :integer(11)   
#

class Asset < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true

  acts_as_cached
  after_save :expire_cache

  has_attachment :storage => :file_system, 
    :content_type => :image,
    :resize_to => '600x600>',
    :thumbnails => {  :large => '400x400>', 
                      :medium => '120x120>', 
                      :small => '50x50>',
                      :tiny => '32x32>', 
                      :toolbar => '24x24>', 
                      :mini => '16x16>',
                      :profile => '175x175>'
    },
    :max_size => 2.megabytes,
    :path_prefix => "public/system/image_assets",
    :processor => :rmagick

  validates_as_attachment

  def before_create
    self.id = create_uuid
  end

  # Override default resize image code to crop thumbnails.
  def resize_image(img, size)
    # If this is the parent image, don't crop - just deal with it in the default manner
    if parent_id.nil?
      super
      return
    end

    # If no crop defined, make a square
    if parent.crop_x1.nil?
      # Get width and height either via width/height methods (ImageScience)
      # or columns/rows methods (RMagick)
      
      w = img.columns
      h = img.rows
      
      # If landscape, crop a square horizonally
      if w > h
        x1 = (w / 2) - (h / 2)
        x2 = x1 + h
        y1 = 0
        y2 = h
      # Otherwise, crop a square vertically
      else
        x1 = 0
        x2 = w
        y1 = (h / 2) - (w / 2)
        y2 = y1 + w
      end
    else
      x1 = parent.crop_x1
      y1 = parent.crop_y1
      x2 = parent.crop_x2
      y2 = parent.crop_y2
    end

    self.temp_path = write_to_temp_file(filename)

    # Ok, sometimes these variables are nil, so let's just check for 
    # that first
    if x1.nil? or x2.nil? or y1.nil? or y2.nil?
      super
      GC.start
      return
    else
      # Crop this image to the parent's crop numbers, and pass the rest of the thumbnailing
      # up the chain to attachment fu's resize_image method.
      img.crop!(x1, y1, x2 - x1, y2 - y1, true)
      GC.start
      super
    end
  end

  # See http://www.37signals.com/svn/archives2/id_partitioning.php
  # Note the explicit cast to int, to handle UUIDs
  def partitioned_path(*args)
    ("%016d" % attachment_path_id.to_i).scan(/..../) + args
  end
end
