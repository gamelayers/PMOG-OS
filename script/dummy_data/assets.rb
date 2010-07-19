@@image_mime_types ||= {".gif" => "image/gif",".ief" => "image/ief",".jpe" => "image/jpeg",".jpeg" => "image/jpeg",".jpg" => "image/jpeg",".pbm" => "image/x-portable-bitmap",
                        ".pgm" => "image/x-portable-graymap",".png" => "image/png",".pnm" => "image/x-portable-anymap",".ppm" => "image/x-portable-pixmap",
                        ".ras" => "image/cmu-raster",".rgb" => "image/x-rgb",".tif" => "image/tiff",".tiff" => "image/tiff",".xbm" => "image/x-xbitmap",
                        ".xpm" => "image/x-xpixmap",".xwd" => "image/x-xwindowdump",}.freeze

class AssetUpload
  def self.upload_image(path, model, type, filename)
    #model.assets.destroy_all
    local_file_path = filename
    content_type ||= @@image_mime_types[File.extname(local_file_path)]
    asset = model.assets.new
    asset.uploaded_data = LocalUploadedFile.new(local_file_path,content_type)
    asset.attachable_type = type
    asset.attachable_id = model.id
    asset.crop_x1 = 0
    asset.crop_y1 = 0
    asset.crop_x2 = 50
    asset.crop_y2 = 50
    asset.save
    
    if ( ! asset.errors.empty? )
      puts asset.errors.full_messages.to_sentence
      raise "Couldn't save asset"
    end
  end
end

class LocalUploadedFile
  # From http://neeraj.name/2007/06/08/migrating-existing-images-to-attachment_fu/
  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename

  # The content type of the "uploaded" file
  attr_reader :content_type

  def initialize(path, content_type = 'text/plain')
    raise "#{path} file does not exist" unless File.exist?(path)

    @content_type = content_type
    @original_filename = path.sub(/^.*#{File::SEPARATOR}([^#{File::SEPARATOR}]+)$/) { $1 }
    @tempfile = Tempfile.new(@original_filename)
    FileUtils.copy_file(path, @tempfile.path)
  end

  def path #:nodoc:
    @tempfile.path
  end

  alias local_path path

  def method_missing(method_name, *args, &block) #:nodoc:
    @tempfile.send(method_name, *args, &block)
  end
end