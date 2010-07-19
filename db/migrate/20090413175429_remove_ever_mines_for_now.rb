class RemoveEverMinesForNow < ActiveRecord::Migration
  def self.up
    @ever_mine = Upgrade.find_by_url_name('ever_mine')
    @ever_mine.destroy unless @ever_mine.nil?
  end

  def self.down
  end
end
