class SkeletonKey

  class SkeletonKeyError < SkeletonKey
  end

  class NotEnoughKeys < SkeletonKeyError
    def default
      "You must summon at least one key at a time."
    end
  end

  def self.create_and_deposit(current_user, params)
    create_skeleton_key_settings = Ability.cached_single(:create_skeleton_key)

    count = (params[:count] ? params[:count].to_i : 0)
    dp_cost = count * create_skeleton_key_settings.dp_cost
    ping_cost = count * create_skeleton_key_settings.ping_cost
    

    raise NotEnoughKeys if count < 1
    raise User::InsufficientDatapointsError.new("You don't have enough datapoints to create #{count} Skeleton Keys.") if current_user.datapoints < dp_cost
    raise User::InsufficientPingsError.new("You don't have enough pings to create #{count} Skeleton Keys.") if current_user.available_pings < ping_cost
    raise User::InsufficientExperienceError.new("You must be a level #{create_skeleton_key_settings.level} Seer to create Skeleton Keys.") if current_user.levels[:seer] < create_skeleton_key_settings.level

    current_user.deduct_datapoints dp_cost
    current_user.deduct_pings ping_cost
    current_user.inventory.deposit :skeleton_keys, count

    Event.record :context => 'skeleton_key_created',
      :user_id => current_user.id,
      :message => count == 1 ? "created a Skeleton Key" : "created #{count} Skeleton Keys"

    count.times do |i|
      current_user.ability_uses.reward :create_skeleton_key
    end

    if count == 1
      "You created 1 Skeleton Key."
    else
      "You created #{count} Skeleton Keys."
    end
  end

end
