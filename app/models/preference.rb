# == Schema Information
# Schema version: 20081220201004
#
# Table name: preferences
#
#  id         :string(36)    primary key
#  user_id    :string(36)    
#  name       :string(255)   not null
#  value      :string(255)   not null
#  created_at :datetime      
#  updated_at :datetime      
#

class Preference < ActiveRecord::Base
  acts_as_cached

  validates_presence_of :name, :value
  
  # Protect internal methods from mass-update.
  attr_accessible :name, :value

  # One massive hash to control the preferences like an enumeration. Kind of tricky to think about
  # when you first start using it, but it gets easier :)  
  def self.preferences 
    {
    :profile_info           => { :ordinal => 1, :text => 'Profile Information',                                :description =>'', :choices => levels_array,  :default => 'Public', :type => 'level',  :group => 'privacy' },
    # :events                 => { :ordinal => 2, :text => 'Events',                                             :description =>'', :choices => levels_array,  :default => 'Public', :type => 'level',  :group => 'privacy' },
    :acquaintances          => { :ordinal => 3, :text => 'Acquaintances',                                      :description =>'', :choices => levels_array,  :default => 'Public', :type => 'level',  :group => 'privacy' },
    :mission_hist           => { :ordinal => 4, :text => 'Mission History',                                    :description =>'', :choices => levels_array,  :default => 'Public', :type => 'level',  :group => 'privacy' },
    :badges                 => { :ordinal => 5, :text => 'Badges',                                             :description =>'', :choices => levels_array,  :default => 'Public', :type => 'level',  :group => 'privacy' },
    # :tool_use               => { :ordinal => 6, :text => 'Tool Use',                                           :description =>'', :choices => levels_array,  :default => 'Public', :type => 'level',  :group => 'privacy' },
    :forum_data             => { :ordinal => 7, :text => 'Forum Information',                                  :description =>'', :choices => levels_array,  :default => 'Public', :type => 'level',  :group => 'privacy' },
    :tags                   => { :ordinal => 8, :text => 'Profile Tags',                                       :description =>'', :choices => levels_array,  :default => 'Public', :type => 'level',  :group => 'privacy' },
    
    :new_acquaintance       => { :ordinal => 1, :text => 'New Allies, Rivals or Acquaintances',                :description =>'', :choices => [true, false], :default => true,     :type => 'boolean', :group => 'email' },
    :weekly_events          => { :ordinal => 2, :text => 'Weekly listing of your Acquaintances\' Event Stream', :description =>'', :choices => [true, false], :default => true,     :type => 'boolean', :group => 'email' },
    :mission_comments       => { :ordinal => 3, :text => 'User/Comment Updates on the Missions you Create',    :description =>'', :choices => [true, false], :default => true,     :type => 'boolean', :group => 'email' },
    :forum_subscript        => { :ordinal => 4, :text => 'Forum Subscriptions',                                :description =>'', :choices => [true, false], :default => true,     :type => 'boolean', :group => 'email' },
    :periodic_updates       => { :ordinal => 5, :text => 'Periodic Updates on The Nethernet',                           :description =>'', :choices => [true, false], :default => true,     :type => 'boolean', :group => 'email' },
                                                                                                                                
    :allow_nsfw             => { :ordinal => 1, :text => 'Allow NSFW Content',                                 :description =>'Not Safe for Work content is more likely to be scary or sexy.  Do you want to see scary and sexy Missions and Portals?', :choices => [true, false], :default => false,     :type => 'boolean', :group => 'content' },
    :sound                  => { :ordinal => 2, :text => 'Allow Sound Effects',                                :description =>'Some events on the web make sounds!  Do you want to hear them?', :choices => [true, false], :default => false,     :type => 'boolean', :group => 'content' },
    :minimum_mission_rating => { :ordinal => 3, :text => 'The Nethernet Mission Content Quality Threshold',             :description =>'You will see only missions rated at, or higher than, this number of stars.', :choices => ['0','1','2','3','4','5'], :default => 3, :type => 'integer', :group => 'content' },
    :minimum_portal_rating  => { :ordinal => 4, :text => 'The Nethernet Portal Content Quality Threshold',              :description =>'You will see only portals rated at, or higher than, this number of stars.', :choices => ['0','1','2','3','4','5'], :default => 3, :type => 'integer', :group => 'content' },
    :skin                   => { :ordinal => 5, :text => 'Extension Skin',                                     :description =>'Before version 0.6, you could change the way your browser skin looks; classic has a pleasant background, plain looks  plain gray, wood has a woody background and night is a dark black.  You will need to restart your browser and log back in to see the effect.  But really you should upgrade to the latest version of The Nethernet and use Firefox themes to change your looks.', :choices => ['classic', 'plain','wood','night'], :default => 'classic', :type => 'text', :group => 'content' }
   }
  end

  # This is a hash of access levels. We have ordinals so we can sort them out in the order we want them to be displayed
  # per justin.
  def self.levels
    {
      :private       => { :ordinal => 1, :text => 'Private'},
      :acquaintances => { :ordinal => 2, :text => 'Acquaintances'},
      :allies        => { :ordinal => 3, :text => 'Allies'},
      :public        => { :ordinal => 4, :text => 'Public'},
    }
  end
  
  @@levels_array = ['Private', 'Acquaintances', 'Allies', 'Public']
  cattr_reader :levels_array
  
  @@privacy_group = [:profile_info, :events, :acquaintances, :mission_hist, :badges, :tool_use]
  cattr_reader :privacy_group
  @@email_group = [:new_acquaintance, :weekly_events, :mission_comments, :forum_subscript, :periodic_updates]
  cattr_reader :content_group
  @@content_group   = [:allow_nsfw, :minimum_portal_rating, :minimum_mission_rating, :sound, :skin]
  cattr_reader :email_group
  
  # Calculate and cache the privacy preferences for this +user+
  def self.privacy_options_for(user)
    get_cache( "privacy_options_for_#{user.id}" ) {
      # Get the preference options for user privacy. These aren't the user preferences
      # but the definition of the preferences
      @privacy_opts = Preference.preferences.select {|k,v| v[:group] == 'privacy'}
    
      # Get the user preference for each privacy option. If they're all private then conceal
      # the profile
      @private_count = 0
      for opt in @privacy_opts do
        pref = user.preferences.get opt[1][:text]
        if pref and pref.value == 'Private'
          @private_count += 1    
        end
      end
      { :privacy_opts => @privacy_opts, :private_count => @private_count }
    }
  end

  def before_create
    self.id = create_uuid
  end
end
