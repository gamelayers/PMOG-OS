class AddPositionToForum < ActiveRecord::Migration
  def self.up
     add_column  :forums, :position, :integer
     #i didn't add a default becuase I'm going to set one in the controller

     #if I currently had a list of forums, I want to go through them and line them up
     #so I need to reset the column information for the forums table so that I can
     #acutally use the position column in this same migration file
     Forum.reset_column_information


     #have to grab all the forums so I can cycle through them
     forums = Forum.find(:all)

     #iterate through the forums and for each one, grab the actual forum and it's
     #position in the array so I can use their position to set their position, if
     #that makes sense
     forums.each_with_index do |f, i|
       f.position = i+1
       #save it with the bang so it I did something naughty, it'll blow up on me
       #it's not necessary f.save should work too
       f.save! 
     end

   end

   def self.down
     #remove the column I just added because not every migration is perfect
     remove_column :forums, :position
   end
end
