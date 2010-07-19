module AvatarHelper
  # Display the user avatar and link to their profile page, options expects :user and :size for now
  # and size can be one of tiny, small, medium and large
  def avatar_link_to_user(options)
    return false if options.empty? or options[:user].nil?
  
    options = { :only_path => true, :class => 'icon' }.merge(options)
    if options[:user].has_avatar? && !options[:user].assets[0].nil?
      img = options[:user].assets[0].public_filename(options[:size])
      #img = (options[:user].assets[0].caches(:public_filename, :with => options[:size], :ttl => 1.day) rescue '/images/shared/elements/user_default.jpg')
    else
      img = '/images/shared/elements/user_default.jpg'
    end
    
    # image_tag doesn't support only_path, so this is a hack :(
    img = host + img unless options[:only_path]
    
    # Sizes taken from asset.rb
    if options[:size] == 'large'
      width = height = 400
    elsif options[:size] == 'profile'
      width = height = 175
    elsif options[:size] == 'medium'
      width = height = 120
    elsif options[:size] == 'small'
      width = height = 50
    elsif options[:size] == 'tiny'
      width = height = 32
    elsif options[:size] == 'mini'
      width = height = 16
    elsif options[:size] == 'toolbar'
      width = height = 24
    else
      width = height = 32
    end
    
    (options[:user].motto.nil? or options[:user].motto.blank?) ? motto = 'omg pmog!' : motto = white_list(options[:user].motto)
    link_to( image_tag( img, :alt => 'avatar image of ' + options[:user].login, :title => options[:user].login + ' says: ' + motto, :width => width, :height => height, :class => options[:class] ), user_path( options[:user], :only_path => options[:only_path] ), :rel => 'contact' )
  end
  
  def avatar_for_user(options)
    img = avatar_path_for_user(options)
    image_tag(img, :alt => 'avatar image of ' + options[:user].login, :title => options[:user].login)
  end
  
  def avatar_path_for_user(options)
    options = { :only_path => true }.merge(options)
    if options[:user].has_avatar? && !options[:user].assets[0].nil?
      # Get the full file path so we can check for its existence.
      full = options[:user].assets[0].full_filename( options[:size] )
      
      # If it doesn't exist, updating the parent asset should force generation of the image
      unless File.exists?(full)
        options[:user].assets[0].update_attributes(nil)
      end
      
      img = options[:user].assets[0].caches(:public_filename, :with => options[:size], :ttl => 1.day)
    else
      size = (options[:size]) ? "_#{options[:size]}" : ''
      img = "/images/shared/elements/user_default#{size}.jpg"
    end
    
    # image_tag doesn't support only_path, so this is a hack :(
    img = host + img unless options[:only_path]
    img
  end
end
