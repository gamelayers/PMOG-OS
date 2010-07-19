class Giftcard < ActiveRecord::Base
  include FirstValidScope
  belongs_to :location
  #belongs_to :old_location
  belongs_to :user

  has_many :dismissals, :as => :dismissable, :dependent => :destroy, :extend => DismissableExtension

  def before_create
    self.id = create_uuid
  end

  class GiftcardError < PMOG::PMOGError
  end

  class BacksiesError < GiftcardError
    def default
      "No backsies!"
    end
  end

  class NoGiftingYourself < GiftcardError
    def default
      "You can't lay DP Cards on your own profile.  Who would pick them up?"
    end
  end

  class << self
    # CHECKED EXCEPTIONS: Location::ErrorNotFound, User::InsufficientDPError, NoGiftingYourself
    def create_and_deposit(current_user, params)
      begin
        @location = Location.find(params[:location_id])
      rescue ActiveRecord::RecordNotFound # humanize for our users
        raise Location::LocationNotFound
      end

      raise NoGiftingYourself if @location.is_users_profile(current_user.login)

      #FIXME reboxing this var to avoid calling memcache 2x, but i'm not sure if that would actually happen either way. delete this comment if you know - alex
      cost = Ability.cached_single(:giftcard).dp_cost

      if current_user.has_enough_datapoints? cost
        current_user.deduct_datapoints cost
        current_user.ability_uses.reward :giftcard
        @giftcard = @location.giftcards.create(:user => current_user)
      else
        raise User::InsufficientDPError
      end

#      domain = 'http://' + Url.caches(:domain, :with => @location.url)
      Event.record :context => 'giftcard_stashed',
        :user_id => current_user.id,
        :message => "left a #{Ability.cached_single(:giftcard).name.singularize} somewhere on <a href=\"http://#{Url.host(@location.url)}\">#{Url.host(@location.url)}</a>"

      return @giftcard
    end
  end

  def loot(current_user, params = {})
    current_user.reward_datapoints(Ability.cached_single(:giftcard).value, false)

    self.user.reward_pings Ping.value('Aid Ally') if self.user.buddies.allied_with? current_user

    Event.record :context => "giftcard_looted",
      :user_id => current_user.id,
      :recipient_id => self.user.id,
      :message => " just took <a href=\"#{self.pmog_host}/users/#{self.user.login}\">#{self.user.login}'s</a> #{Ability.cached_single(:giftcard).name.singularize} on <a href=\"#{self.location.url}\">#{Url.host(self.location.url)}</a>",
      :details => "You left this DP Card at <a href='#{self.location.url}'>#{self.location.url}</a> on #{self.created_at.to_s}"
  end

  def dismiss(current_user, params)
    @window_id = params[:window_id].nil? ? self.id : params[:window_id]
    self.dismissals.dismiss current_user unless self.dismissals.dismissed_by? current_user
  end

  # A JSON representation of a 'found' crate
  def to_json_overlay(extra_args = {})
    Hash[
      :id => id,
      :location_id => self.location.id,
      :user => self.user.login
    ].merge(extra_args).to_json
  end

end

