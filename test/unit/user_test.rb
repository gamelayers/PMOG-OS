require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users, :missions, :levels, :user_levels

  def setup
    @error_messages = ActiveRecord::Errors::default_error_messages
    @valid_user = users(:pmog)
    @invalid_user = users(:invalid_user)
    super
  end

  # Replace this with your real tests.
  def test_user_validity
    assert @valid_user.valid?
  end

  def test_user_invalidity
    assert ! @invalid_user.valid?
    attributes = [:email]
    attributes.each do |attribute|
      assert @invalid_user.errors.invalid?(attribute)
    end
  end

  def test_uniqueness_of_login_and_email
    user_repeat = User.new(:login    => @valid_user.login,
                           :email    => @valid_user.email,
                           :password => @valid_user.password,
                           :date_of_birth => @valid_user.date_of_birth)
    assert !user_repeat.valid?
    assert_equal @error_messages[:taken], user_repeat.errors.on(:login)
    assert_equal @error_messages[:taken], user_repeat.errors.on(:email)
  end

  def test_login_minimum_length
    user = @valid_user
    min_length = User::LOGIN_MIN_LENGTH

    # Login is too short
    user.login = "a" * (min_length - 1)
    assert !user.valid?, "#{user.login} should raise a minumum length error"
    # Format the error message based on minimum length
    correct_error_message = sprintf(@error_messages[:too_short], min_length)
    assert_equal [correct_error_message, correct_error_message], user.errors.on(:login)

    # Login is minimum length
    user.login = "a" * min_length
    assert user.valid?, "#{user.login} should be just long enough to pass"
  end

  def test_login_maximum_length
    user = @valid_user
    max_length = User::LOGIN_MAX_LENGTH

    # Login is too long
    user.login = "a" * (max_length + 1)
    assert !user.valid?, "#{user.login} should raise a maximum length error"
    # Format the error message
    correct_error_message = sprintf(@error_messages[:too_long], max_length)
    assert_equal correct_error_message, user.errors.on(:login)

    # Login is maximum length
    user.login = "a" * max_length
    assert user.valid?, "#{user.login} should be just short enough to pass"
  end

  def test_url_valid_format
    user = @valid_user
    invalid_error = "must start with http:// or https:// and end with a .tld (Top level domain)"

    user.url = "no.valid"
    assert !user.valid?
    assert_equal invalid_error, user.errors.on(:url)

    user.url = "ftp://pmog.com"
    assert !user.valid?
    assert_equal invalid_error, user.errors.on(:url)

    user.url = "pmog.com"
    assert !user.valid?
    assert_equal invalid_error, user.errors.on(:url)

    user.url = "http://pmog.com"
    assert user.valid?
    assert_nil user.errors.on(:url)

    user.url = ""
    assert user.valid?
    assert_nil user.errors.on(:url)

    user.url = nil
    assert user.valid?
    assert_nil user.errors.on(:url)
  end

  def test_pronouns
    user = users(:suttree)
    assert user.male?
    assert_equal 'he', user.subjective_name
    assert_equal 'him', user.objective_name
    assert_equal 'himself', user.reflective_name
    assert_equal 'his', user.possessive_name
    assert_equal 'his', user.determiner_name

    user.gender = 'f' # Ouch! Sorry about this duncan

    assert user.female?
    assert_equal 'she', user.subjective_name
    assert_equal 'her', user.objective_name
    assert_equal 'herself', user.reflective_name
    assert_equal 'hers', user.possessive_name
    assert_equal 'her', user.determiner_name

    user.gender = nil # what?!

    assert_equal 'they', user.subjective_name
    assert_equal 'them', user.objective_name
    assert_equal 'themselves', user.reflective_name
    assert_equal 'theirs', user.possessive_name
    assert_equal 'their', user.determiner_name
  end

  # Identity url should either be set, or not
  def test_zero_value_identity_url
    user = users(:suttree)

    # These should fail
    user.identity_url = '0'
    assert_equal false, user.save

    user.identity_url = '01'
    assert_equal false, user.save

    # These variations should pass
    user.identity_url = ''
    assert_equal true, user.save

    user.identity_url = nil
    assert_equal true, user.save

    user.identity_url = '012'
    assert_equal true, user.save

    user.identity_url = 'www.suttree.com'
    assert_equal true, user.save

    user.identity_url = 'http://does.not.exist.com' # yeh, this should pass
    assert_equal true, user.save
  end

  def test_reward
    user = users(:suttree)
    dp = user.datapoints
    total_dp = user.total_datapoints

    user.reward_datapoints(200)
    assert_equal (dp + 200), user.datapoints
    assert_equal (total_dp + 200), user.total_datapoints

    user.deduct_datapoints(200)
    dp = user.datapoints
    total_dp = user.total_datapoints

    user.reward_datapoints(500)
    assert_equal (dp + 500), user.datapoints
    assert_equal (total_dp + 500), user.total_datapoints
  end

  def test_deduct
    user = users(:suttree)
    dp = user.datapoints
    total_dp = user.total_datapoints

    user.deduct_datapoints(200)
    assert_equal 0, user.datapoints
    assert_equal total_dp, user.total_datapoints

    user.reward_datapoints(500)

    user.deduct_datapoints(200)
    assert_equal 300, user.datapoints
    assert_equal total_dp + 500, user.total_datapoints

    user.deduct_datapoints(12345)
    assert_equal 0, user.datapoints
    assert_equal total_dp + 500, user.total_datapoints
  end

  def test_equip
    user = users(:suttree)

    # prep
    assert_equal false, user.is_armored?
    user.inventory.set( :armor, 2 )

    assert_difference lambda{user.inventory.reload.armor}, :call, -1 do
      user.toggle_armor
      assert_equal true, user.is_armored?
    end
  end

  def test_unequip
    user = users(:suttree)

    assert_equal false, user.is_armored?

    user.inventory.set( :armor, 2 )
    user.toggle_armor
    armor_total = user.inventory.reload.armor

    assert_equal true, user.is_armored?
    user.toggle_armor

    assert_equal (armor_total + 1), user.inventory.reload.armor
    assert_equal false, user.is_armored?
  end

# DISABLED by alex, reimplement when needed
#  def test_possible_allies
#    @suttree = users(:suttree)
#    @marc = users(:marc)
#    marc_pre = @marc.buddies.potential_allies.size
#    suttree_pre = @suttree.buddies.potential_allies.size
#    @e = Event.create(:user_id => @suttree.id, :recipient_id => @marc.id, :message => 'oh hai!', :context => 'crate_looted')
#    assert @e.valid?
#    assert @suttree.events.friendly.find(@e.id)
#
#    # Marc should now see Suttree as a potential ally because he looted the crate.
#    assert_equal marc_pre+1, @marc.buddies.potential_allies.size
#    assert @marc.buddies.potential_allies.map{ |x|x.id }.include?(@suttree.id)
#    assert !@marc.buddies.potential_allies.map{ |x|x.id }.include?(@marc.id)
#
#    # Suttree should now see Marc because he looted his crate
#    assert_equal suttree_pre+1, @suttree.buddies.potential_allies.size
#    assert @suttree.buddies.potential_allies.map{ |x|x.id }.include?(@marc.id)
#    assert !@suttree.buddies.potential_allies.map{ |x|x.id }.include?(@suttree.id)
#
#    # If they are already allies they should not see each other in the list.
#  end

  def test_possible_rivals
  end

  def test_wholesomeness_invalid
    user = User.new
    user.login                 = "fucker"
    user.email                 = "fucker@here.com"
    user.password              = "fuckfuckfuck"
    user.password_confirmation = "fuckfuckfuck"
    user.date_of_birth         = '1975-02-19 00:47:40'

    assert_equal false, user.valid?
    assert_equal "is unavailable", user.errors.on(:login)
  end

  def test_wholesomeness_valid
    user = User.new
    user.login                 = "sunshine"
    user.email                 = "happy@there.com"
    user.password              = "smilesmilesmile"
    user.password_confirmation = "smilesmilesmile"
    user.date_of_birth         = '1975-02-19 00:47:40'

    assert_equal true, user.valid?, "Uh oh, something's wrong."

    user.errors.each do |e|
      puts e.to_s
    end
  end
end
