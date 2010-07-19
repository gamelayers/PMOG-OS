ActionController::Routing::Routes.draw do |map|
  map.home '', :controller => 'home'
  map.connect 'unsubscribe', :controller => 'unsubscribe_request', :action => 'index'
  map.connect 'unsubscribe/campaign_monitor', :controller => 'unsubscribe_request', :action => 'campaign_monitor'

  map.versions "about/versions", :controller => 'about', :action => 'versions'
  map.toolbar  "help/toolbar", :controller => 'help', :action => 'toolbar'
  # This is to allow ajaxiness on the missions view for the highest rated
  map.top 'missions/top', :controller => 'missions', :action => 'highest_rated'

  # This is to allow ajaxiness on the missions view for the PMOG-related
  map.pmog 'missions/pmog', :controller => 'missions', :action => 'pmog_missions'

  # This is to allow ajaxiness on the missions view for user favorites
  map.favorites 'missions/favorites', :controller => 'missions', :action => 'user_favorites'

  map.search 'missions/search', :controller => 'missions', :action => 'search'

  map.forum_search 'forums/search', :controller => 'forums', :action => 'search'

  map.with_options :controller => 'missions' do |missions|
    # Displays the new mission generator form
    missions.new_generator 'generator/new', :action => 'new'
    # Shows the form to add and organize lightposts
    missions.show_lightposts 'generator/:id/lightposts', :action => 'lightposts'
    # Action to save the lightposts to the mission
    missions.save_lightposts 'generator/:id/lightposts/save', :action => 'save_lightposts'
    # Mission test page
    missions.mission_test 'generator/:id/test', :action => 'test'
    # The view to launch the user out on a test of their own mission.
    missions.overview 'generator/:id/overview', :action => 'overview'
    # The final view of the mission generator, after the author test
    missions.publish_mission 'generator/:id/publish', :action => 'publish'
  end

  map.resources :user_secrets

  map.resources :queued_mission

  map.resources :events

  map.resource :hud

  map.resource :openid, :member => { :complete => :get }
  map.resource :session

  map.status '/status.json', :controller => 'users', :action => 'status', :format => 'json'

  map.invites 'invite/windows_live', :controller => 'invite', :action => 'windows_live', :conditions => { :method => :post }

  map.checkuser '/checkuser', :controller => 'users', :action => 'checkuser', :method => :get

  map.signup '/signup.json', :controller => 'users', :action => 'signup', :method => :get, :format => 'json'

  map.resources :quests, :member => { :required_for => :get, :order => :any, :set_requirement => :put } do |quests|
    quests.resources :goals, :name_prefix => "quest_", :controller => "goals", :member => { :add => :post }
  end

  map.resource :goal

  map.resources :beta_users
  map.resources :levels
  map.resources :pmog_classes
  map.resources :tools
  map.resources :upgrades
  map.resources :abilities
  map.resources :exceptions, :member => { :bug_report => :post }
  map.resources :tags

  # For admin browsing/deleting of tools, and MOTDs
  map.resources :crates, :collection => { :search => :get }
  map.resources :giftcards, :collection => { :search => :get }
  map.resources :mines, :collection => { :search => :get }
  map.resources :watchdogs, :collection => { :search => :get }
  map.resources :portals, :collection => { :search => :get, :jaunt => :get }
  map.resources :motd, :member => { :dismiss => :post }
  map.resources :game_settings

  # If you want /players/suttree instaed of /users/suttree, uncomment this line and
  # create the relevant controller like this - class PlayersController < UsersController
  #map.resources :players, :controller => 'users'

  map.resources :users, :collection => { :search => :get },
                        :member => { :play => :post,
                                     :set_primary_class => :post,
                                     :findfriends => :any,
                                     :add_tag => :put,
                                     :remove_tag => :delete,
                                     :delete_assets => :delete,
                                     :reset_login_delay => :delete } do |user|
    # UserAssetsController knows how to deal with the
    # polymorphic relationship between an Asset and its
    # 'attachable'.
    # We use the resource_fu :opaque_name option so that the
    # url looks clean independent of url helper and route names.
    user.resources :user_assets, :opaque_name => :assets
    user.resources :inventory
    user.resources :events, :collection => { :mark_all_read => :get, :ticker => :get, :contacts => :get, :triggered => :get, :combined => :get }
    user.resources :lightposts, :member => { :replace_line => :put }, :collection => { :sort => :get }
    user.resources :faves
    user.resources :badges
    user.resources :tags, :controller => 'user_tags'
    user.resource  :hospital, :controller => 'jira_user', :member => { :register => :post }
    user.resources :missions, :collection => { :favorites => :get,
                                               :taken => :get,
                                               :generated => :get,
                                               :queued => :get },
                              :member => { :favorite => :put,
                                           :unfavorite => :delete,
                                           :queue => :put,
                                           :dequeue => :delete,
                                           :add_tag => :put,
                                           :remove_tag => :delete }

    user.resources :messages, :collection => { :sent => :get,
                                               :summon => :post,
                                               :invite => :post,
                                               :system => :get
                                              },
                              :member => { :summoned => :post,
                                           :dismiss => :post,
                                           :reply => :post,
                                           :read => :put
                                         }

    # In Rails, POST is create and PUT is update...
    user.resource :armor, :member => { :equip => :put, :unequip => :put }
    user.resource :ability_status, :member => { :toggle_armor => :put, :toggle_dodge => :put, :toggle_disarm => :put, :toggle_vengeance => :put }
    user.resource :st_nicks, :member => { :attach => :put }
    user.resource :grenades, :member => { :attach => :put }
    user.resource :giftcards, :member => { :attach => :put }
    user.resource :preferences
    user.resource :skeleton_keys, :controller => 'skeleton_keys', :member => { :create => :put }
  end

  map.resources :missions, :collection => { :latest => :get },
                           :member => { :take => :get,
                                        :guess => :post,
                                        :complete => :post,
                                        :dismiss => :post,
                                        :abandon => :post,
                                        :load => :any,
                                        :share => :post,
                                        :add_lightpost => :post,
                                        :remove_lightpost => :delete } do |mission|
    mission.resources :branches, :member => { :read_more => :get }
    mission.resources :tags, :controller => 'mission_tags'
  end

  #map.resources :bird_bots do |bird_bot|
  #  bird_bot.resources :bird_bot_assets, :opaque_name => :assets
  #  bird_bot.resources :feeds
  #  bird_bot.resources :locations
  #  bird_bot.resources :messages
  #end

  #map.resources :npcs do |npc|
  #  npc.resources :npc_assets, :opaque_name => :assets
  #  npc.resources :feeds
  #  npc.resources :locations
  #  npc.resources :messages
  #end

  map.resources :forums, :member => { :move => :any }, :collection => { :stewards => :get } do |forum|
    forum.resources :topics, :member => { :lock => :any,
                                          :unlock => :any,
                                          :pin => :any,
                                          :unpin => :any,
                                          :hide => :post,
                                          :unhide => :post,
                                          :subscribe => :any,
                                          :unsubscribe => :any } do |topic|
      topic.resources :posts, :member => { :hide => :post }
    end
  end

  #Added for the comments 01/18/2008 marc@gamelayers.com
  map.resources :comments, :member => { :destroy => :delete }
  map.resources :tags
  map.resources :track
  map.resources :allies
  map.resources :rivals
  map.resources :shoppe, :collection => { :buy => :post }, :member => { :purchase => :put }
  map.resources :acquaintances do |acquaintance|
    acquaintance.resources :events, :collection => { :ticker => :get }
  end

  # RESTful description of a url
  map.resources :locations, :collection => { :search => :get } do |location|
    location.resources :mines
    location.resources :watchdogs, :collection => { :attach => :post }
    location.resources :portals, :member => { :take => :get, :rate => :post, :dismiss => :post, :vote => :post }
    location.resources :crates, :member => { :loot => :put, :dismiss => :post, :withdraw => :put, :deposit => :put }
    location.resources :giftcards, :member => { :loot => :put, :dismiss => :post }
    location.resources :lightposts
    location.resources :faves
  end


  # Add an interesting route to call before the track. Just to check if there is anything on the page.
  map.connect '/interesting.json', :controller => 'track', :action => 'interesting', :format => "json"

  map.connect '/forums/search', :controller => 'forums', :action => 'searchin'

  #map.connect '/quest/:id/goals/order', :controller => 'goals', :action => 'order'

  map.connect 'mission_shares/optout/:id', :controller => 'mission_shares', :action => 'optout'
  map.connect 'mission_shares/mission/:id', :controller => 'mission_shares', :action => 'mission'

  map.connect 'awsm-attack/:action/:id', :controller => 'awsmattack'
  map.connect 'awsm-attack.json', :controller => 'awsmattack', :format => 'json'

  # Exception logger
  map.connect   'logged_exceptions/:action/:id', :controller => 'logged_exceptions', :action => 'index', :id => nil

  # Handle the track controller and Firefox stats calls from outdated versions of the PMOG v1 extension
  map.connect 'track/*url', :controller => 'home', :action => 'deprecated_track'
  map.connect 'firefox/stats', :controller => 'home', :action => 'deprecated_firefox_stats'

  # The old news.bud.com, which we'll forward to the relevant blog
  map.connect 'news', :controller => 'home', :action => 'deprecated_news'
  map.connect 'news/feed/atom', :controller => 'home', :action => 'deprecated_news_feed_atom'
  map.connect 'index.xml', :controller => 'home', :action => 'deprecated_index_xml'

  # Hard wiring this route, not sure why it doesn't appear by default, don't have the time to debug either.
  map.connect 'posts/latest.rss', :controller => 'posts', :action => 'latest', :format => 'rss'
  map.connect 'posts/latest_for_weblog.rss', :controller => 'posts', :action => 'latest_for_weblog', :format => 'rss'

  map.connect '/toolbarlanding' , :controller => 'home', :action => 'toolbarlanding'

  map.connect 'robots.txt', :controller => 'home', :action => 'robots'

  # These are set in the relevant plugin, but seem to be needed here too
  map.connect '/clientperf', :controller => 'clientperf', :action => 'index'
  map.connect '/clientperf/measure.gif', :controller => 'clientperf', :action => 'measure'
  map.connect '/clientperf/reset', :controller => 'clientperf', :action => 'reset'
  map.connect '/clientperf/:id', :controller => 'clientperf', :action => 'show'
  map.connect '/clientperf/:id/reset', :controller => 'clientperf', :action => 'reset'

  # Direct the url /join/<user login> to the referrer controller
  map.connect '/join/:id', :controller => 'referrer', :action => 'index'

  # payments
  map.connect '/payments/gambit', :controller => 'get_gambit', :action => 'create'

  # helpdesk
  map.connect '/helpdesk/logout', :controller => 'zendesk_login', :action => 'logout'
  map.connect '/helpdesk', :controller => 'zendesk_login'#, :action => 'index'
 # map.connect '/guide/support', :controller => 'zendesk_login', :action =>'index'

  #  oauth support
  map.connect '/oauth/:id', :controller => 'users', :action => 'oauth_authorize'
  map.connect '/oauth/new/:id', :controller => 'users', :action => 'oauth_authorize'
  map.connect '/oauth/success/:id', :controller => 'users', :action => 'oauth_success'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
