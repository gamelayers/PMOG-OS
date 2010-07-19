class MigrateOldUserLevels < ActiveRecord::Migration
  def self.up
    # SEEDING XP PER LEVEL
    @lv1 = Level.find_by_level("1")
    @lv1.classpoints = 0
    @lv1.save
    @lv2 = Level.find_by_level("2")
    @lv2.classpoints = 25
    @lv2.save
    @lv3 = Level.find_by_level("3")
    @lv3.classpoints = 50
    @lv3.save
    @lv4 = Level.find_by_level("4")
    @lv4.classpoints = 100
    @lv4.save
    @lv5 = Level.find_by_level("5")
    @lv5.classpoints = 200
    @lv5.save
    @lv6 = Level.find_by_level("6")
    @lv6.classpoints = 300
    @lv6.save
    @lv7 = Level.find_by_level("7")
    @lv7.classpoints = 500
    @lv7.save
    @lv8 = Level.find_by_level("8")
    @lv8.classpoints = 1000
    @lv8.save
    @lv9 = Level.find_by_level("9")
    @lv9.classpoints = 1500
    @lv9.save
    @lv10 = Level.find_by_level("10")
    @lv10.classpoints = 2400
    @lv10.save
    @lv11 = Level.find_by_level("11")
    @lv11.classpoints = 3300
    @lv11.save
    @lv12 = Level.find_by_level("12")
    @lv12.classpoints = 5250
    @lv12.save
    @lv13 = Level.find_by_level("13")
    @lv13.classpoints = 7500
    @lv13.save
    @lv14 = Level.find_by_level("14")
    @lv14.classpoints = 8750
    @lv14.save
    @lv15 = Level.find_by_level("15")
    @lv15.classpoints = 10000
    @lv15.save
    @lv16 = Level.find_by_level("16")
    @lv16.classpoints = 15000
    @lv16.save
    @lv17 = Level.find_by_level("17")
    @lv17.classpoints = 20000
    @lv17.save
    @lv18 = Level.find_by_level("18")
    @lv18.classpoints = 27500
    @lv18.save
    @lv19 = Level.find_by_level("19")
    @lv19.classpoints = 37500
    @lv19.save
    @lv20 = Level.find_by_level("20")
    @lv20.classpoints = 50000
    @lv20.save

    # SEEDING XP PER ACTION
    # also storing action_xp locally, outside the main loop
    Tool.reset_column_information
  
    armor_xp = 30
    @armor = Tool.find_by_name('armor')
    @armor.classpoints = armor_xp
    @armor.save
    crate_xp = 15
    @crates = Tool.find_by_name('crates')
    @crates.classpoints = crate_xp
    @crates.save
    puzzle_crate_xp = 25 #addative to benefactor w/ standard crate
    @puzzle = Upgrade.find_by_url_name('puzzle_crate')
    @puzzle.classpoints = puzzle_crate_xp
    @puzzle.save
    mine_xp = 5
    @mines = Tool.find_by_name('mines')
    @mines.classpoints = mine_xp
    @mines.save
    exploding_crate_xp = 15 #addative to destroyer only, benefactor points are canceled invisibly
    @exploding = Upgrade.find_by_url_name('exploding_crate')
    @exploding.classpoints = exploding_crate_xp
    @exploding.save
    lightpost_xp = 10
    @lightposts = Tool.find_by_name('lightposts')
    @lightposts.classpoints = lightpost_xp
    @lightposts.save
    portal_xp = 15
    @portals = Tool.find_by_name('portals')
    @portals.classpoints = portal_xp
    @portals.save
    abundant_portal_xp = 20 #addative to seer w/ standard portal
    @abundant = Upgrade.find_by_url_name('give_dp')
    @abundant.classpoints = abundant_portal_xp
    @abundant.save
    st_nick_xp = 10
    @nicks = Tool.find_by_name('st_nicks')
    @nicks.classpoints = st_nick_xp
    @nicks.save
    watchdog_xp = 15
    @dogs = Tool.find_by_name('watchdogs')
    @dogs.classpoints = watchdog_xp
    @dogs.save
    dpcard_xp = 5
    @cards = Ability.find_by_url_name('giftcard')
    @cards.classpoints = dpcard_xp
    @cards.save

# Uncomment this File related jibber jabber for some logs if you want them
#    File.open("#{RAILS_ROOT}/log/userlevels_migration.log", 'r+') do |f|   # open file for update

#      f.print "===========================================================================\n"
#      f.print "Beginning Users migration on #{@users.size} records\n"

      User.find(:all).each { |user|
        next unless user.user_level.nil?
        if user.tool_uses.length > 0
          ul = UserLevel.create(
            :user_id => uid,
            :bedouin_cp => user.tool_uses.uses(:armor)*armor_xp,
            :benefactor_cp => user.tool_uses.uses(:crates)*crate_xp + user.upgrade_uses.uses(:puzzle_crate)*puzzle_crate_xp - user.upgrade_uses.uses(:exploding_crate)*crate_xp,
            :destroyer_cp => user.tool_uses.uses(:mines)*mine_xp + user.upgrade_uses.uses(:exploding_crate)*exploding_crate_xp,
            :pathmaker_cp => user.tool_uses.uses(:lightposts)*lightpost_xp,
            :seer_cp => user.tool_uses.uses(:portals)*portal_xp + user.upgrade_uses.uses(:give_dp)*abundant_portal_xp - user.upgrade_uses.uses(:give_dp)*portal_xp,
            :vigilante_cp => user.tool_uses.uses(:st_nicks)*st_nick_xp + user.tool_uses.uses(:watchdogs)*watchdog_xp
          )
          # set the primary class equal to the highest amount of cp they have
          ul.auto_assign_primary
          # unless the player is too low level for this to be a useful metric of what they care about
          if(ul.primary < 5)
            ul.primary_class = 'shoat'
            ul.save
          end
         end

#        f.print "#{ul.inspect}\n"
      }

#    end
  end

  def self.down
    # just where do you think you're going
  end
end
