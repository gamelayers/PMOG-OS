class InsertPuzzlePostIntoUpgrades < ActiveRecord::Migration
  def self.up
    puzzle_post_data = { :name => "Puzzle Post",
      :url_name => 'puzzle_post',
      :ping_cost => 200,
      :level => 7,
      :classpoints => 100,
      :pmog_class_id => PmogClass.find_by_name("Pathmakers").id,
      :short_description => "Puzzle Posts don't allow a player to progress through a mission until they have answered a question." }

    @puzzle_post = Upgrade.find_by_url_name('puzzle_post')
    @puzzle_post.nil? ? Upgrade.create(puzzle_post_data) : @puzzle_post.update_attributes(puzzle_post_data)
  end

  def self.down
    @puzzle_post = Upgrade.find_by_url_name('puzzle_post')
    @puzzle_post.destroy unless @puzzle_post.nil?
  end
end
