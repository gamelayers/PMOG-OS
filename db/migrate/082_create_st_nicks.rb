# Shit, shit, shit. I forgot all about this and committed without editing the template
# migration. See migration 085 - CreateStNicksAgain - for the real deal - duncan 19/12/2007
class CreateStNicks < ActiveRecord::Migration
  def self.up
    create_table :st_nicks do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :st_nicks
  end
end
