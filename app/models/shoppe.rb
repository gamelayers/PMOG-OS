class Shoppe < ActiveRecord::Base
  @@order_limit = 10
  cattr_reader :order_limit
  
  class ShoppeError < PMOG::PMOGError
  end
  
  class InsufficientFundsError < ShoppeError
    def default
      "You do not have enough datapoints to purchase these items."
    end
  end
  
  class EmptyOrderError < ShoppeError
    def default
      "Your order is empty"
    end
  end
  
  class TooManyItemsError < ShoppeError
    def default
      "You cannot purchase more than #{Shoppe.order_limit} items at one time."
    end
  end

  class SkeletonKeyError < ShoppeError
    def default
      "You can't buy Skeleton Keys!  Go bargain with a Seer."
    end
  end

  class << self
    def buy(current_user, params)
      # gotta use 'quotes' instead of :symbols to get the individual tool names out.  damned if i know why -alex
      raise EmptyOrderError.new if item_count(params[:order][:tools]) < 1
      raise TooManyItemsError.new if item_count(params[:order][:tools]) > Shoppe.order_limit
      raise InsufficientFundsError.new unless has_enough_funds(current_user, params[:order][:tools])
      raise User::InsufficientExperienceError.new("You are too low level to purchase Watchdogs.") if (params[:order][:tools]['watchdogs'].to_i > 0 && current_user.levels[:vigilante] < Tool.cached_single(:watchdogs).level)
      raise User::InsufficientExperienceError.new("You are too low level to purchase Grenades.") if (params[:order][:tools]['grenades'].to_i > 0 && current_user.levels[:destroyer] < Tool.cached_single(:grenades).level)
      raise SkeletonKeyError if params[:order][:tools]['skeleton_keys'].to_i > 0

      params[:order][:tools].each_pair do |k,v|
        t = Tool.cached_single(k.to_s)
        total_cost = t.cost * v.to_i
        current_user.inventory.deposit( t.url_name, v.to_i )
        current_user.deduct_datapoints(total_cost)
      end
    end
    
    private
    
    def has_enough_funds(current_user, items ={})
      funds = current_user.reload.datapoints
      items.each_pair do |k, v|
        t = Tool.cached_single(k.to_s)
        funds -= t.cost * v.to_i
        return false if funds <= 0
      end
      true
    end
        
    def item_count(items = {})
      items.values.inject( nil ) { |sum,x| sum ? sum + x.to_i : x.to_i } || 0
    end
  end
end
