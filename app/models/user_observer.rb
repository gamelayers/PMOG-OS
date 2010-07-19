class UserObserver < ActiveRecord::Observer
  def after_create(user)
    user.datapoints = 0
    user.total_datapoints = 0

    # build the user's level record immediately
    UserLevel.create(:user_id => user.id)
    AbilityStatus.create(:user_id => user.id)
    Inventory.create(:owner_id => user.id, :owner_type => 'User')

    # Initialize user preferences with the default.
    user.init_preferences

    # Shout it from the mountain top!
    # the signup event has been moved to the users_controller

    # starting inventory: 10 of each tool and some extra lightposts
    user.inventory.deposit :mines, 10
    user.inventory.deposit :armor, 10
    user.inventory.deposit :st_nicks, 10
    user.inventory.deposit :portals, 10
    user.inventory.deposit :lightposts, 30

    # Update the Associations which are protected from mass assignment.
    # user.primary_association = 'Shoat'
    # user.secondary_association = 'Shoat'
    # user.tertiary_association = 'Shoat'
    user.save(false)

    # Have some beta keys
    2.times do
      user.beta_keys.create
    end

    # Send the new user a welcome message.
    if not user.email.nil?
      Mailer.deliver_new_user(
        :subject => 'TheNethernet Welcome Email',
        :recipients => user.email,
        :body => { :user => user }
      )
    end

    # Queue a tutorial mission, and PMail it to the user
    #mission = Mission.find_by_url_name('welcome_to_the_nethernet')
    #user.missions_queued << mission unless mission.nil?

    # FIXME when we overhaul mail from @pmog

    #burdenday = User.find_by_login('merci')
    #burdenday.reward_datapoints(2, false) # postage aint free bro
    #Message.create_and_deposit(burdenday,
    #                           :pmail_message => "Welcome to The Nethernet!  I'm your Community Liaison. Take this starter mission to learn how to play: http://thenethernet.com/missions/welcome_to_the_nethernet",
    #                           :pmail_to => '@' + user.login
    #                          )

    # Create the remember me token needed for logging in using cookies
    user.remember_me
  end
end
