class MissionRatingsCounterCache < ActiveRecord::Migration
  def self.up
    add_column :missions, :total_ratings, :integer, :default => 0
    Mission.reset_column_information
    execute( "update missions, (select rateable_id, count(*) as count from ratings group by rateable_id) as mission_ratings set missions.total_ratings = mission_ratings.count where missions.id = mission_ratings.rateable_id")
  end

  def self.down
    remove_column :missions, :total_ratings
    Mission.reset_column_information
  end
end
