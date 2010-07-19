require 'test_helper'

class StatusEffectTest < ActiveSupport::TestCase
  fixtures :users, :user_levels, :game_settings, :abilities, :ability_statuses, :badges, :pings

  def setup
    # alex is a benefactor, he can use overclock
    @alex = users(:alex)
    @alex.badges << Badge.find_by_name('Inviting')
    # marc is a destroyer, he can use impede
    @marc = users(:marc)
    @marc.badges << Badge.find_by_name('Inviting')
  end

  def test_overclock_no_inviting_badge
    @alex.badges.clear

    assert_raises StatusEffect::NoPlayersInvited do
      StatusEffect.overclock @alex, "marc"
    end
  end

  def test_overclock_bad_login
    assert_raises User::PlayerNotFound do
      StatusEffect.overclock @alex, "pixley wigglebottom"
    end
  end

  def test_overclock_out_of_casts
    @alex.ability_status.daily_invite_buffs = 0
    @alex.ability_status.save

    assert_raises StatusEffect::NoCastsLeft do
      StatusEffect.overclock @alex, "marc"
    end
  end

  #FIXME hardcoded numbers
  def test_already_overclocked
    @alex.ability_status.daily_invite_buffs = 6
    @alex.ability_status.save

    5.times do 
      StatusEffect.overclock @alex, "marc"
    end

    assert_raises StatusEffect::TooManyCharges_Overclock do
      StatusEffect.overclock @alex, "marc"
    end
  end

  def test_overclock_self
    assert_raises StatusEffect::NoSelfBuffs do
      StatusEffect.overclock @alex, "atfriedman"
    end
  end

  def test_overclock_as_chaos
    assert_raises StatusEffect::WrongFaction do
      StatusEffect.overclock @marc, "atfriedman"
    end
  end

  def test_overclock_success
    assert_difference AbilityUse, :count do
    assert_difference lambda{@alex.reload.available_pings}, :call, Ping.value('Aid Ally') do
    assert_difference StatusEffect, :count do
      StatusEffect.overclock @alex, "marc"
    end end end
  end

  def test_impede_no_inviting_badge
    @marc.badges.clear

    assert_raises StatusEffect::NoPlayersInvited do
      StatusEffect.impede @marc, "atfriedman"
    end
  end

  def test_impede_bad_login
    assert_raises User::PlayerNotFound do
      StatusEffect.impede @marc, "pixley wigglebottom"
    end
  end

  def test_impede_out_of_casts
    @marc.ability_status.daily_invite_buffs = 0
    @marc.ability_status.save

    assert_raises StatusEffect::NoCastsLeft do
      StatusEffect.impede @marc, "atfriedman"
    end
  end

  #FIXME hardcoded numbers
  def test_already_impeded
    @marc.ability_status.daily_invite_buffs = 6
    @marc.ability_status.save

    5.times do 
      StatusEffect.impede @marc, "atfriedman"
    end

    assert_raises StatusEffect::TooManyCharges_Impede do
      StatusEffect.impede @marc, "atfriedman"
    end
  end

  def test_impede_as_chaos
    assert_raises StatusEffect::WrongFaction do
      StatusEffect.impede @alex, "marc"
    end
  end

  def test_impede_success
    assert_difference AbilityUse, :count do
    assert_difference lambda{@marc.reload.available_pings}, :call, Ping.value('Damage Rival') do
    assert_difference StatusEffect, :count do
      StatusEffect.impede @marc, "atfriedman"
    end end end
  end

end
