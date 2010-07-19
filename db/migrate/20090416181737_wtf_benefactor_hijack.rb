class WtfBenefactorHijack < ActiveRecord::Migration
  def self.up
    @stealth_mine = Upgrade.find_by_url_name('stealth_mine')
    @stealth_mine.update_attributes(:pmog_class_id => PmogClass.find_by_name("Destroyers").id)

    @abundant_mine = Upgrade.find_by_url_name('abundant_mine')
    @abundant_mine.update_attributes(:pmog_class_id => PmogClass.find_by_name("Destroyers").id)

    @vengeance = Ability.find_by_url_name('vengeance')
    @vengeance.update_attributes(:pmog_class_id => PmogClass.find_by_name("Bedouins").id)

    @skeleton_key = Tool.find_by_url_name('skeleton_keys')
    @skeleton_key.update_attributes(:pmog_class_id => PmogClass.find_by_name("Seers").id)

    @create_skeleton_key = Ability.find_by_url_name('create_skeleton_key')
    @create_skeleton_key.update_attributes(:pmog_class_id => PmogClass.find_by_name("Seers").id)
  end

  def self.down
  end
end
