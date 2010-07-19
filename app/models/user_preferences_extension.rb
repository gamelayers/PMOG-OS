module UserPreferencesExtension
  # Return the value of +name+ preference
  def setting(name)
    proxy_owner.get_cache( 'setting_' + name.to_s ) do
      current_preference = find( :first, :conditions => { :name => name.to_s } )
      current_preference.nil? ? nil : current_preference.value
    end
  end

  # Sets an initial preference, by calling toggle
  def set(name, value)
    toggle(name, value)
  end

  # Gets the current value for the supplied preference name
  def get(name)
    proxy_owner.get_cache( 'get_' + name.to_s ) do
      find( :first, :conditions => { :name => name.to_s } )
    end
  end

  # Update or set, the value of +name+ preference
  def toggle(name, value)
    current_preference = find( :first, :conditions => { :name => name.to_s } )
    if current_preference.nil?
      current_preference = create( :name => name.to_s, :value => value.to_s )
    else
      current_preference.value = value.to_s
      current_preference.save
    end
    expire_cache( 'get_' + name.to_s )
    expire_cache( 'setting_' + name.to_s )
    current_preference
  end
  
  def expire_cache(key)
    proxy_owner.expire_cache(key)
  end
  
  # Ensure we set the defaults for preferences in case they don't already exist.
  def ensure_defaults_for(opts ={})
    opts.each_pair do |k,v|
      set(k,v) unless setting(k)
    end
    self
  end
  
  def update_all(prefs = [])
    prefs.each_pair do |k,v|
      toggle(k,v)
    end
    self
  end
  
  # Reducing the number of events the user will see
  # Note that you will always seen your own overlays, though
  def falls_below_quality_threshold(overlay)
    proxy_owner.get_cache(overlay, :ttl => 1.week) do
      sym = "minimum_#{overlay.class.to_s.downcase}_rating".to_sym
      preference = proxy_owner.preferences.get( Preference.preferences[sym][:text] )
      preference.nil? ? threshold = nil : threshold = preference.value
      rating = overlay.average_rating
      ((rating.to_i < threshold.to_i) && (overlay.user.id != proxy_owner.id))
    end
  end
  
  # Filtering NSFW content, or not
  # Users who want to see NSFW stuff will get it, wheras users who don't want to
  # will only see their own stuff that is NSFW.
  def falls_outside_nsfw_threshold(overlay)
    proxy_owner.get_cache(overlay, :ttl => 1.week) do
      pref = proxy_owner.preferences.get( Preference.preferences[:allow_nsfw][:text] )
      allow_nsfw = (pref) ? pref.value.to_bool : false
      if allow_nsfw
        false
      elsif overlay.nsfw?
        if (overlay.user.id == proxy_owner.id)
          false
        else
          true
        end
      else
        false
      end
    end
  end
end