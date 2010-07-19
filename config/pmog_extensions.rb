# Classes, as related to tool usage
#CLASSES = { :crates => 'Benefactor', :portals => 'Seer', :mines => 'Destroyer', :lightposts => 'Pathmaker', :armor => 'Bedouin', :walls => 'Riveter', :st_nicks => 'Vigilante', :rockets => 'Grenadier' }
CLASSES = { :crates => 'Benefactor', :portals => 'Seer', :mines => 'Destroyer', :lightposts => 'Pathmaker', :armor => 'Bedouin', :st_nicks => 'Vigilante' }

# NOTE i'm hijacking this to serve as a light-weight access version of a url_name mapping from the Tool table.  it wasnt being used anywhere -alex
# Tools, as related to class usage
#TOOLS = { :benefactor => 'crates', :seer => 'portals', :destroyer => 'mines', :pathmaker => 'lightposts', :bedouin => 'armor', :vigilante => 'st_nicks' }
TOOLS = [:armor, :crates, :grenades, :lightposts, :mines, :portals, :skeleton_keys, :st_nicks, :watchdogs]
# these are all the things that can be traded (go in crate inventories)
ITEMS = [:armor, :crates, :datapoints, :grenades, :lightposts, :mines, :pings, :portals, :skeleton_keys, :st_nicks, :watchdogs]

INVITE_RESPONSE = [ "That worked! But you have a fever and the only cure is more invites!",
                    "On its way! Would you like to invite more people?",
                    "Invite sent! We'll be your best friends if you invite another!",
                    "w00t! You'll be the wind beneath our wings if you invite another!",
                    "Awesome! Want to invite someone else?"
  ]

# This takes the profile owner, viewer and the section to display and checks the profile owners privacy preferences
# to determine if the requested content can be shown to the viewer.
def show_content?(profile_owner, profile_viewer, content)
  @allow = false

  # Here we go to the database and get the profile owner's privacy for the
  # requested content.
  @content_preference = profile_owner.preferences.get content

  if @content_preference.nil?
    profile_owner.preferences.set content, "Public"

    # We just set the value, now we have to initialize it again
    @content_preference = profile_owner.preferences.get content
  end

  # Per Justin: If the viewer is logged out but the profile is set to public, show them anyway
  if profile_viewer.nil?
    if @content_preference.value.downcase.to_sym == :public
      return true
    else
      return false
    end
  end

  # Only proceed if the owner and the viewer are the same. We don't want to hide
  # content from the owner!
  if (profile_owner == profile_viewer or site_admin?)
    #logger.debug "[SHOW_TO] The owner and the viewer are the same or it's a trustee, show them everything"
    return true
  end

  #logger.debug "[SHOW_TO] " + profile_owner.login + "'s preference for " + content + " is " + @content_preference.value
  #logger.debug "[SHOW_TO] preference value: :" + @content_preference.value.downcase

  case @content_preference.value.downcase.to_sym
    when :public:         @allow = true
    when :private:        @allow = false
    when :acquaintances:  @allow = true if profile_owner.buddies.acquainted_with? profile_viewer
    when :allies:         @allow = true if profile_owner.buddies.allied_with? profile_viewer
    else                  @allow = false
  end

  #logger.debug "[SHOW_TO] Are we showing? " + @allow.to_s
  return @allow
end

# The default PMOG user, changed from PMOG_USER to SYSTEM_USER - duncan 23/02/09
# Note that the email for this user is still 'self@pmog.com' though, as we use
# that elsewhere in the code, and it works fine.
if User.table_exists?
  SYSTEM_USER = User.find_by_email( 'self@pmog.com' )
end

PMOG_EXTENSION_VERSION = YAML::load(ERB.new(IO.read("#{RAILS_ROOT}/config/xpi.yml")).result)['hud']['version']

# PMOG_CSS_VERSION = YAML::load(ERB.new(IO.read("#{RAILS_ROOT}/config/xpi.yml")).result)['css']['version']
