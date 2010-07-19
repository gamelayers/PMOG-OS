# == Schema Information
# Schema version: 20081220201004
#
# Table name: crate_upgrades
#
#  id              :string(36)    default(""), not null, primary key
#  crate_id        :string(36)
#  puzzle_question :string(255)
#  puzzle_answer   :string(255)
#  exploding       :boolean(1)
#  created_at      :datetime
#  updated_at      :datetime
#

class CrateUpgrade < ActiveRecord::Base
  belongs_to :crate

  validates_presence_of :crate_id
  validates_uniqueness_of :crate_id

  # DEBUG ERRORS
  # phrased in polite english in the event that they ever end up in front of a user, but that should never happen

  class CrateUpgradeError < Crate::CrateError
    def default
      "There was an error upgrading your Crate."
    end
  end

  class NoUpgradeSpecified < CrateUpgradeError
    def default
      "Sorry! The Nethernet is confused!  Please specify your upgrade again."
    end
  end

  class PuzzleCrate_NoAnswer < CrateUpgradeError
    def default
      "Oops! Somehow we didn't get your answer.  Please enter it again."
    end
  end

  # USER FACING ERRORS

  class InsufficientPings < CrateUpgradeError
    def default
      "You do not have enough pings to purchase this upgrade!"
    end
  end

  class PuzzleCrate_NoQuestion < CrateUpgradeError
    def default
      "You must have a Puzzle in order to lock a Crate."
    end
  end

  class PuzzleCrate_WrongAnswer < CrateUpgradeError
    def default
      "Guess again! Your answer is incorrect."
    end
  end

  class Puzzlecrate_NoSkeletonKeys < CrateUpgradeError
    def default
      "You need to have a Skeleton Key in order to unlock a Crate."
    end
  end

  class ExplodingCrate_NoMines < CrateUpgradeError
    def default
      "You need Mines if you want to trap a Crate."
    end
  end

  class ExplodingCrate_HasTools < CrateUpgradeError
    def default
      "You can't put tools in an Exploding Crate.  Where would you fit the detonator?"
    end
  end

  class EverCrate_OnProfile < CrateUpgradeError
    def default
      "You can't leave an Ever Crate on a user's profile page."
    end
  end

  class EverCrate_NoCharges <  CrateUpgradeError
    def default
      "Ever Crates must have at least two charges"
    end
  end

  class EverCrate_TooManyCharges <  CrateUpgradeError
    def default
      "You don't have enough resources to fill your Ever Crate this many times."
    end
  end

  def is_answer?(attempt = nil)
    attempt && (attempt.strip.chomp.downcase == self.puzzle_answer.strip.chomp.downcase)
  end

  class << self
    def create_and_use(current_crate, params)
      # this is for exploding crates.  it bugs me that we have the same var over in the crate, but it hasnt been saved yet so we can't read it
      params[:charges].to_i > 0 ? charges = params[:charges].to_i : charges = 1

      if(params[:locked].to_bool)
        current_crate.user.upgrade_uses.reward :puzzle_crate
        current_crate.user.deduct_pings(Upgrade.cached_single('puzzle_crate').ping_cost)
      end

      if(params[:charges].to_i > 0)
        current_crate.user.upgrade_uses.reward :ever_crate
        current_crate.user.deduct_pings(Upgrade.cached_single('ever_crate').ping_cost)
      end

      if(params[:exploding].to_bool)
        current_crate.user.upgrade_uses.reward :exploding_crate
        current_crate.user.deduct_pings(Upgrade.cached_single('exploding_crate').ping_cost * charges)
        current_crate.user.inventory.withdraw :mines, Upgrade.cached_single('exploding_crate').mine_cost * charges
      end

      @deployed_upgrade = current_crate.create_crate_upgrade(
        :puzzle_question => params[:question],
        :puzzle_answer => params[:answer],
        :exploding => params[:exploding],
        :ever_crate => params[:charges].to_i > 0 )

      @deployed_upgrade
    end
  end

  def before_create
    self.id = create_uuid
  end
end
