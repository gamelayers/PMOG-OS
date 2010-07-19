class UpdatePmogClassesRelations < ActiveRecord::Migration
  def self.up
    # leave the characters column on tools
    # misc actions don't have classes
    # remove all old string
    # add class_id to tools/abilities/actions for the rails relations

    remove_column :abilities, :association_id
    remove_column :upgrades, :association_id
    remove_column :misc_actions, :association_id

    add_column :tools, :pmog_class_id, :int
    add_column :abilities, :pmog_class_id, :int
    add_column :upgrades, :pmog_class_id, :int

    PmogClass.reset_column_information 
    Tool.reset_column_information
    Ability.reset_column_information
    Upgrade.reset_column_information

    # cache class objects locally
    benefactor = PmogClass.find_by_name('Benefactors').id
    seer = PmogClass.find_by_name('Seers').id
    destroyer = PmogClass.find_by_name('Destroyers').id
    pathmaker = PmogClass.find_by_name('Pathmakers').id
    vigilante = PmogClass.find_by_name('Vigilantes').id
    bedouin = PmogClass.find_by_name('Bedouins').id

    # fill in data for all currently implemented game actions
    actions = {}
    data = {}

    actions[:abundant_portal] = Upgrade.find_by_url_name('give_dp')
    data[:abundant_portal] = seer
    actions[:puzzle_crate] = Upgrade.find_by_url_name('puzzle_crate')
    data[:puzzle_crate] = benefactor
    actions[:exploding_crate] = Upgrade.find_by_url_name('exploding_crate')
    data[:exploding_crate] = destroyer
    actions[:ever_crate] = Upgrade.find_by_url_name('ever_crate')
    data[:ever_crate] = benefactor

    actions[:dp_card] = Ability.find_by_url_name('giftcard')
    data[:dp_card] = benefactor
    actions[:dodge] = Ability.find_by_url_name('dodge')
    data[:dodge] = bedouin
    actions[:disarm] = Ability.find_by_url_name('disarm')
    data[:disarm] = bedouin
    actions[:vengeance] = Ability.find_by_url_name('vengeance')
    data[:vengeance] = bedouin

    actions[:crates] = Tool.find_by_name('crates')
    data[:crates] = benefactor
    actions[:lightposts] = Tool.find_by_name('lightposts')
    data[:lightposts] = pathmaker
    actions[:mines] = Tool.find_by_name('mines')
    data[:mines] = destroyer
    actions[:portals] = Tool.find_by_name('portals')
    data[:portals] = seer
    actions[:st_nicks] = Tool.find_by_name('st_nicks')
    data[:st_nicks] = vigilante
    actions[:armor] = Tool.find_by_name('armor')
    data[:armor] = bedouin
    actions[:watchdogs] = Tool.find_by_name('watchdogs')
    data[:watchdogs] = vigilante
    actions[:grenades] = Tool.find_by_name('grenades')
    data[:grenades] = destroyer

    # write it all down now
    actions.each do |k, v|
      v.update_attributes(:pmog_class_id => data[k]) unless v.nil?
    end

  end

  def self.down
    add_column :abilities, :association_id, :string
    add_column :upgrades, :association_id, :string
    add_column :misc_actions, :association_id, :string

    remove_column :tools, :pmog_class_id
    remove_column :abilities, :pmog_class_id
    remove_column :upgrades, :pmog_class_id

    remove_index :pmog_classes, :name
  end
end
