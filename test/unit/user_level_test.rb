require File.dirname(__FILE__) + '/../test_helper'

class UserLevelTest < ActiveSupport::TestCase
  fixtures :users, :user_levels, :abilities, :tools

  def setup
    @alex = users(:alex)
  end

  def test_user_recieves_classpoints
    card_settings = Ability.find_by_url_name('giftcard')

    assert_difference lambda{@alex.user_level.benefactor_cp}, :call, card_settings.classpoints do
      @alex.ability_uses.reward(:giftcard)
    end
  end

  def test_overclocked_user_recieves_more_classpoints
    buff_settings = Ability.find_by_url_name('overclock')
    s = StatusEffect.create(:user_id => @alex.id, :charges => buff_settings.charges, :ability_id => buff_settings.id)

    card_settings = Ability.find_by_url_name('giftcard')

    assert_difference lambda{s.reload.charges}, :call, -1 do
    assert_difference lambda{@alex.user_level.benefactor_cp}, :call, card_settings.classpoints + buff_settings.value do
      @alex.ability_uses.reward(:giftcard)
    end end
  end

  def test_expired_overclock_does_not_give_more_classpoints
    buff_settings = Ability.find_by_url_name('overclock')
    StatusEffect.create(:user_id => @alex.id, :charges => 0, :ability_id => buff_settings.id)

    card_settings = Ability.find_by_url_name('giftcard')

    assert_difference lambda{@alex.user_level.benefactor_cp}, :call, card_settings.classpoints do
      @alex.ability_uses.reward(:giftcard)
    end
  end

  def test_impeded_user_recieves_less_classpoints
    buff_settings = Ability.find_by_url_name('impede')
    StatusEffect.create(:user_id => @alex.id, :charges => buff_settings.charges, :ability_id => buff_settings.id)

    card_settings = Ability.find_by_url_name('giftcard')

    assert_difference lambda{@alex.user_level.benefactor_cp}, :call, card_settings.classpoints - buff_settings.value do
      @alex.ability_uses.reward(:giftcard)
    end
  end

  def test_level_up_via_datapoints
    # grab a shoat
    user = users(:alex)
    assert_equal 0, user.total_datapoints
    assert_equal user.current_level, 1

    user.tool_uses.reward(:crates)
    user.tool_uses.reward(:crates)
    user.tool_uses.reward(:crates)
    assert_equal user.current_level, 1

    assert_difference(Event, :count) do
      user.reward_datapoints(1000)
    end

    assert_equal 2, user.reload.current_level
  end

  def test_level_up_via_classpoints
    # grab a shoat
    user = users(:alex)
    assert_equal 0, user.total_datapoints
    assert_equal user.current_level, 1

    # reward enough dp to level (but not enough cp)
    user.reward_datapoints(1000)
    assert_equal user.current_level, 1

    assert_equal 1000, user.total_datapoints

    assert_difference(Event, :count) do
      # deploy a bunch of crates, this will auto set the shoat's level to the highest active class and give them the levelup event
      user.tool_uses.reward(:crates)
      user.tool_uses.reward(:crates)
      user.tool_uses.reward(:crates)
    end

    assert_equal 2, user.reload.current_level
  end

  def test_non_primary_levelup
    user = users(:alex)
    assert_equal 0, user.total_datapoints
    assert_equal user.current_level, 1
    user.user_level.primary_class="benefactor"

    # reward enough dp to level (but not enough cp)
    user.reward_datapoints(1000)
    assert_equal user.current_level, 1

    assert_difference(Event, :count) do
      user.tool_uses.reward(:mines)
      user.tool_uses.reward(:mines)
      user.tool_uses.reward(:mines)
      user.tool_uses.reward(:mines)
      user.tool_uses.reward(:mines)
      user.tool_uses.reward(:mines)
      user.tool_uses.reward(:mines)
    end

    assert_equal 1, user.reload.current_level
    assert_equal 2, user.user_level.reload.destroyer
  end

end
