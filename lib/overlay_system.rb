# Methods for use in the Firefox overlays
module OverlaySystem
  include AvatarHelper
  # Cutting down on the repetitive code caused by rendering overlays.
  # Intended to make rendering an overlay to the extension as simple as this:
  #
  # render :json => create_overlay(@portal, :template => 'portals/new')
  #
  # Note that +model+ can be an instantiated model, e.g. @portal, or a
  # new record, e.g. Lightpost.new or a string, e.g. 'st_nick'. Note also that
  # +options[:event_name]+ can be set to specify the +event_name+ that forms
  # a key in the JSON hash.
  #
  # Note also that we force templates to use a '.js.erb' extension, so that
  # we don't end up duplicating overlays for .js and .json formats.
  def create_overlay(model, options={})
    options = { :type => nil, :disable_id => false }.merge(options)
    model_name, event_name = set_model_and_event_name(model, options)
    @tool_id = options[:text][:id] if options[:text]
    overlay = {}
    overlay[event_name] = []
    overlay[event_name] << model_name.to_hash({ :id => @tool_id, :type => options[:type] }) do
      render_to_string :text => options[:text].to_json, :layout => false
    end

    # Ensure that the type is underscored.
    overlay[event_name].first[:type] = overlay[event_name].first[:type].underscore if overlay[event_name].first[:type]
    # Fixes a bug whereby donning or removing armor sends back an id
    # which means that no other subsequent tool interactions work.
    # If specified by :disable_id => true, we blank out the id field
    overlay[event_name][0][:id] = nil if options[:disable_id].to_bool

    if options[:mission_text_template]
      overlay[event_name][0][:mission_text] = render_to_string :partial => options[:mission_text_template], :layout => false
    end

    # Add the animation elements if there are any
    overlay[event_name][0][:post] = options[:post] if options[:post]
    overlay[event_name].flatten!

    # Now add a bunch of generic data
    overlay[:user] = current_user_data
    add_empty_page_objects_to(overlay)
    add_version_number_to(overlay)
    return OpenStruct.new(overlay).send(:table).to_json
  end

  # For rendering nothing, for the messages controller
  def create_empty_overlay
    overlay = {}
    overlay[:user] = current_user_data if logged_in?
    add_empty_page_objects_to(overlay)
    add_version_number_to(overlay)
    return OpenStruct.new(overlay).send(:table).to_json
  end

  # For rendering errors overlays
  def create_error_overlay(body, options = {})
    overlay = { :errors => [] }
    @body = body
    overlay[:errors] << { :type => 'error', :subject => 'Error', :body => { :content => body, :from => 'PMOG' } }
    overlay[:errors].flatten!

    # Now add a bunch of generic data
    #overlay[:user] = current_user_data if logged_in?
    #add_empty_page_objects_to(overlay)
    #add_version_number_to(overlay)
    return OpenStruct.new(overlay).send(:table).to_json
  end

  def render_full_json_response(overlay={}, tracking=false)
    overlay[:user] = current_user_data(:tracking => tracking) if logged_in?
    #add_empty_page_objects_to(overlay)
    add_version_number_to(overlay)
    add_buffs_to(overlay)
    return OpenStruct.new(overlay).send(:table).to_json
  end

  # Special case overlay for logins via the extension
  def create_new_session_overlay
    overlay = {}
    overlay[:user] = current_user_data
    #add_empty_page_objects_to(overlay)
    add_version_number_to(overlay)
    return OpenStruct.new(overlay).send(:table).to_json
  end

  # For communication with the browser extension. On every request we want to return
  # the latest user data, so this method can be called to add that data to any
  # OpenStruct model. Use this method to add the user data to your hash,
  # which in turn will be turned into an OpenStruct. Note that we send
  # +form_authenticity_token+ to the extension so that it can embed that
  # and return it to us as +authenticity_token+ so that we can use the
  # csrf killing features of +protect_from_forgery+
  def current_user_data(opts = {})

    user = { :user_id => current_user.id,
      :auth_token => current_user.remember_token,
      :login => current_user.login,
      :level => current_user.current_level,
      :levels => current_user.levels,
      :next_level => current_user.current_level + 1,
      :level_percentage => current_user.level_dp_percentage,
      :level_cp_percentage => current_user.level_cp_percentage,
      :primary_association => current_user.user_level.primary_class,
      :datapoints => current_user.datapoints,
      :motto => current_user.motto,
      :total_datapoints => current_user.total_datapoints,
      :watchdogs => current_user.inventory.watchdogs,
      :mines => current_user.inventory.mines,
      :grenades => current_user.inventory.grenades,
      :portals => current_user.inventory.portals,
      :crates => current_user.inventory.crates,
      :lightposts => current_user.inventory.lightposts,
      :history => { :light_posts => lightpost_history,
        :queued_missions => queued_missions_history },
      :skeleton_keys => current_user.inventory.skeleton_keys,
      :st_nicks => current_user.inventory.st_nicks,
      :recent_badges => current_user.recent_badges,
      :recent_events => current_user.recent_events,
      :armor => current_user.inventory.armor,
      :armored => current_user.is_armored?,
      :armor_charges => current_user.ability_status.armor_charges,
      :dodge => current_user.ability_status.dodge,
      :disarm => current_user.ability_status.disarm,
      :vengeance => current_user.ability_status.vengeance,
      :buddies => current_user.buddies.recently_active,
      :avatar_mini => avatar_path_for_user(:user => current_user, :size => 'mini'),
      :avatar_tiny => avatar_path_for_user(:user => current_user, :size => 'tiny'),
      :avatar_toolbar => avatar_path_for_user(:user => current_user, :size => 'toolbar'),
      :sound_preference => current_user.preferences.setting('Allow Sound Effects'),
      :skin => current_user.preferences.setting('Extension Skin'),
      :authenticity_token => form_authenticity_token,
      :next_invite_badge => current_user.caches(:next_invite_badge),
      :available_pings => current_user.available_pings,
      :lifetime_pings => current_user.lifetime_pings,
      :unread_messages => current_user.messages.unread_count,
      :faction => current_user.user_level.order_or_chaos?,
      :can_overclock => user_can_overclock,
      :can_impede => user_can_impede,
      :daily_invite_buffs => current_user.ability_status.daily_invite_buffs
    }

    if current_user.status_effects.length > 0
      user[:buffs] = status_effects_for_user(current_user)
    end

    if opts[:tracking]
      user[:unread_system_messages_count] = current_user.system_events.unread_count
      user[:unread_system_messages] = system_notices
    end

    return user
  end

  def user_can_overclock
    inviting_badge ||= Badge.caches(:find_by_name, :with => 'Inviting')

    current_user.badges.include? inviting_badge and current_user.user_level.order_or_chaos? == "order"
  end

  def user_can_impede
    inviting_badge ||= Badge.caches(:find_by_name, :with => 'Inviting')

    current_user.badges.include? inviting_badge and current_user.user_level.order_or_chaos? == "chaos"
  end

  def status_effects_for_user(current_user)
    status_effects = {}

    current_user.status_effects.each do |e|
      status_effects[e.ability.url_name] = { :source => User.find(e.source_id).login, :charges => e.charges, :timestamp => e.updated_at, :avatar => avatar_path_for_user(:user => User.find(e.source_id), :size => 'tiny') }
    end

    status_effects
  end

  def add_buffs_to(overlay)
    buffs = current_user.status_effects.find( :all, :conditions => { :shown => false } )
    unless buffs.length <= 0
      overlay[:status_effects] = []
      buffs.each do |b|
        overlay[:status_effects] << StatusEffect.to_hash(:id => b.id, :type => b.ability.url_name, :relationship => current_user.buddies.relationship(User.find(b.source_id))) do
          render_to_string :text => b.to_json_overlay()
        end
        # Make sure we only show this once.
        b.show!
      end
    end
  end

  def lightpost_history
    current_user.get_cache('lightpost_history', :ttl => 1.day) do
      current_user.lightposts[0..9].collect{ |x| Hash['id' => x.id, 'description' => x.description, 'url' => x.location.url] unless x.location.nil? }
    end
  end

  # Deprecated, moved to queued_mission_controller. Remove post 0.6.3
  def queued_missions_history
    current_user.get_cache('queued_missions_history', :ttl => 1.day) do
      current_user.queued_missions[0..9].collect{ |x|
        next if x.mission.nil?
        Hash['name' => x.mission.name, 'url' => host + '/missions/' + x.mission.url_name]
      }
    end
  end

  def system_notices
    messages = current_user.system_events.most_recent_unread

    json_messages = []
    messages.each do |m|
      json_messages << m.for_overlay
      m.read!
    end
    return json_messages
  end

  # The extension expects a list of every available page object as a result of each API
  # call. So here we can have a list of +page_objects+ which we add to the +overlay+
  # unless they are already set. Call this as the last thing before rendering the hash
  # as json for digesting by the extension.
  def add_empty_page_objects_to(overlay)
    page_objects = [ :portals, :portal_rating, :st_nicks, :lightposts, :missions, :mission_rating, :mines, :crates, :tags, :errors, :messages, :user, :flash , :crate_contents ]
    page_objects.each do |page|
      overlay[page] = [] if overlay[page].nil?
    end
    overlay
  end

  # So that we can tell users when to update. Note that +PMOG_EXTENSION_VERSION+
  # is set in config/pmog_extensions.rb and so is PMOG_CSS_VERSION for that matter.
  def add_version_number_to(overlay)
    overlay[:version] = PMOG_EXTENSION_VERSION
    # overlay[:css_version] = PMOG_CSS_VERSION
    overlay
  end

  # Add all of the +current_user+ data to the overlay hash
  # def add_user_data_to(overlay, with_events)
  #   overlay[:user] = current_user_data
  #   overlay
  # end

  # Will check for an :auth_token parameter and log the user back in if apropriate
  # It's a simple copy of login_from_cookie from authenticated_system
  def login_from_browser
    return unless params[:auth_token]
    user = User.find_by_remember_token(params[:auth_token])
    if user && user.remember_token?
      user.remember_me
      self.current_user = user
    end
  end

  # The extension expects messages to have keys for content, from and avatar.
  # This method is a helper to ensure those keys are filled out.
  def message_overlay(opts = {})
    options = { :id => nil, :content => nil, :from => nil, :avatar => nil }.merge(opts)
    unless options[:from]
      u = User.find_by_login('PMOG')
      options[:from] = u.login
      options[:avatar] = avatar_path_for_user(:user => u, :size => 'tiny')
    end
    options
  end

  protected
  # Determine the event name from +model+
  def set_event_name(model)
    model.class.table_name.to_sym
  end

  # Determine the model and table name from +model+ or +options[:event_name]+
  def set_model_and_event_name(model, options)
    if model.is_a? String
      [ model.classify.singularize.camelize.constantize, model.pluralize.to_sym ]
    elsif options[:event_name]
      [ model.class.name.singularize.camelize.constantize, options[:event_name].to_sym ]
    else
      [ model.class.name.singularize.camelize.constantize, model.class.table_name.to_sym ]
    end
  end
end
