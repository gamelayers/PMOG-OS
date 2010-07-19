class DefaultLevelValues < ActiveRecord::Migration
  def self.up
    level = Level.find_by_level(1)
    level.update_attributes("portals_deployed"=>0, "lightposts_deployed"=>0, "armors_donned"=>0, "portals_taken"=>0, "missions_taken"=>0, "walls_deployed"=>0, "datapoints"=>0, "rockets_fired"=>0, "missions_created"=>0, "mines_deployed"=>0, "st_nicks_attached"=>0, "crates_deployed"=>0)

    level = Level.find_by_level(2)
    level.update_attributes("portals_deployed"=>5, "lightposts_deployed"=>4, "armors_donned"=>5, "portals_taken"=>10, "missions_taken"=>2, "walls_deployed"=>0, "datapoints"=>1000, "rockets_fired"=>0, "missions_created"=>0, "mines_deployed"=>5, "st_nicks_attached"=>5, "crates_deployed"=>5)

    level = Level.find_by_level(3)
    level.update_attributes("portals_deployed"=>10, "lightposts_deployed"=>8, "armors_donned"=>10, "portals_taken"=>20, "missions_taken"=>6, "walls_deployed"=>0, "datapoints"=>3000, "rockets_fired"=>0, "missions_created"=>1, "mines_deployed"=>10, "st_nicks_attached"=>10, "crates_deployed"=>10)

    level = Level.find_by_level(4)
    level.update_attributes("portals_deployed"=>15, "lightposts_deployed"=>12, "armors_donned"=>15, "portals_taken"=>30, "missions_taken"=>12, "walls_deployed"=>0, "datapoints"=>7000, "rockets_fired"=>0, "missions_created"=>3, "mines_deployed"=>15, "st_nicks_attached"=>15, "crates_deployed"=>15)
                                                                                                                                               
    level = Level.find_by_level(5)                                                                                                             
    level.update_attributes("portals_deployed"=>20, "lightposts_deployed"=>20, "armors_donned"=>20, "portals_taken"=>40, "missions_taken"=>15, "walls_deployed"=>0, "datapoints"=>15000, "rockets_fired"=>0, "missions_created"=>5, "mines_deployed"=>20, "st_nicks_attached"=>20, "crates_deployed"=>20)
                                                                                                                                               
    level = Level.find_by_level(6)                                                                                                             
    level.update_attributes("portals_deployed"=>30, "lightposts_deployed"=>50, "armors_donned"=>30, "portals_taken"=>60, "missions_taken"=>25, "walls_deployed"=>0, "datapoints"=>30000, "rockets_fired"=>0, "missions_created"=>10, "mines_deployed"=>30, "st_nicks_attached"=>30, "crates_deployed"=>30)
                                                                                                                                               
    level = Level.find_by_level(7)                                                                                                             
    level.update_attributes("portals_deployed"=>40, "lightposts_deployed"=>60, "armors_donned"=>40, "portals_taken"=>80, "missions_taken"=>30, "walls_deployed"=>0, "datapoints"=>45000, "rockets_fired"=>0, "missions_created"=>12, "mines_deployed"=>40, "st_nicks_attached"=>40, "crates_deployed"=>40)
                                                                                                                                               
    level = Level.find_by_level(8)                                                                                                             
    level.update_attributes("portals_deployed"=>50, "lightposts_deployed"=>70, "armors_donned"=>50, "portals_taken"=>100, "missions_taken"=>40, "walls_deployed"=>0, "datapoints"=>70000, "rockets_fired"=>0, "missions_created"=>14, "mines_deployed"=>50, "st_nicks_attached"=>50, "crates_deployed"=>50)
                                                                                                                                               
    level = Level.find_by_level(9)                                                                                                             
    level.update_attributes("portals_deployed"=>60, "lightposts_deployed"=>80, "armors_donned"=>60, "portals_taken"=>120, "missions_taken"=>50, "walls_deployed"=>0, "datapoints"=>85000, "rockets_fired"=>0, "missions_created"=>16, "mines_deployed"=>60, "st_nicks_attached"=>60, "crates_deployed"=>60)

    level = Level.find_by_level(10)
    level.update_attributes("portals_deployed"=>70, "lightposts_deployed"=>90, "armors_donned"=>70, "portals_taken"=>140, "missions_taken"=>65, "walls_deployed"=>0, "datapoints"=>115000, "rockets_fired"=>0, "missions_created"=>20, "mines_deployed"=>70, "st_nicks_attached"=>70, "crates_deployed"=>70)

    level = Level.find_by_level(11)
    level.update_attributes("portals_deployed"=>80, "lightposts_deployed"=>120, "armors_donned"=>80, "portals_taken"=>160, "missions_taken"=>75, "walls_deployed"=>0, "datapoints"=>145000, "rockets_fired"=>0, "missions_created"=>22, "mines_deployed"=>80, "st_nicks_attached"=>80, "crates_deployed"=>80)

    level = Level.find_by_level(12)
    level.update_attributes("portals_deployed"=>90, "lightposts_deployed"=>140, "armors_donned"=>90, "portals_taken"=>180, "missions_taken"=>85, "walls_deployed"=>0, "datapoints"=>190000, "rockets_fired"=>0, "missions_created"=>24, "mines_deployed"=>90, "st_nicks_attached"=>90, "crates_deployed"=>90)

    level = Level.find_by_level(13)
    level.update_attributes("portals_deployed"=>100, "lightposts_deployed"=>160, "armors_donned"=>100, "portals_taken"=>200, "missions_taken"=>95, "walls_deployed"=>0, "datapoints"=>240000, "rockets_fired"=>0, "missions_created"=>26, "mines_deployed"=>100, "st_nicks_attached"=>100, "crates_deployed"=>100)
                                                                                                                                                                                                                                                                                                        
    level = Level.find_by_level(14)                                                                                                                                                                                                                                                                     
    level.update_attributes("portals_deployed"=>110, "lightposts_deployed"=>180, "armors_donned"=>110, "portals_taken"=>220, "missions_taken"=>100, "walls_deployed"=>0, "datapoints"=>290000, "rockets_fired"=>0, "missions_created"=>28, "mines_deployed"=>110, "st_nicks_attached"=>110,"crates_deployed"=>110)
                                                                                                                                                                                                                                                                                           
    level = Level.find_by_level(15)                                                                                                                                                                                                                                                        
    level.update_attributes("portals_deployed"=>120, "lightposts_deployed"=>200, "armors_donned"=>120, "portals_taken"=>240, "missions_taken"=>110, "walls_deployed"=>0, "datapoints"=>360000, "rockets_fired"=>0, "missions_created"=>33, "mines_deployed"=>120, "st_nicks_attached"=>120,"crates_deployed"=>120)
                                                                                                                                                                                                                                                                                           
    level = Level.find_by_level(16)                                                                                                                                                                                                                                                        
    level.update_attributes("portals_deployed"=>130, "lightposts_deployed"=>220, "armors_donned"=>130, "portals_taken"=>260, "missions_taken"=>115, "walls_deployed"=>0, "datapoints"=>410000, "rockets_fired"=>0, "missions_created"=>35, "mines_deployed"=>130, "st_nicks_attached"=>130,"crates_deployed"=>130)
                                                                                                                                                                                                                                                                                           
    level = Level.find_by_level(17)                                                                                                                                                                                                                                                        
    level.update_attributes("portals_deployed"=>145, "lightposts_deployed"=>240, "armors_donned"=>145, "portals_taken"=>280, "missions_taken"=>120, "walls_deployed"=>0, "datapoints"=>460000, "rockets_fired"=>0, "missions_created"=>37, "mines_deployed"=>145, "st_nicks_attached"=>145,"crates_deployed"=>145)
                                                                                                                                                                                                                                                                                           
    level = Level.find_by_level(18)                                                                                                                                                                                                                                                        
    level.update_attributes("portals_deployed"=>165, "lightposts_deployed"=>250, "armors_donned"=>165, "portals_taken"=>300, "missions_taken"=>125, "walls_deployed"=>0, "datapoints"=>520000, "rockets_fired"=>0, "missions_created"=>39, "mines_deployed"=>165, "st_nicks_attached"=>165,"crates_deployed"=>165)
                                                                                                                                                                                                                                                                                           
    level = Level.find_by_level(19)                                                                                                                                                                                                                                                        
    level.update_attributes("portals_deployed"=>185, "lightposts_deployed"=>260, "armors_donned"=>185, "portals_taken"=>320, "missions_taken"=>130, "walls_deployed"=>0, "datapoints"=>590000, "rockets_fired"=>0, "missions_created"=>41, "mines_deployed"=>185, "st_nicks_attached"=>185,"crates_deployed"=>185)
                                                                                                                                                                                                                                                                                           
    level = Level.find_by_level(20)                                                                                                                                                                                                                                                        
    level.update_attributes("portals_deployed"=>205, "lightposts_deployed"=>280, "armors_donned"=>205, "portals_taken"=>340, "missions_taken"=>140, "walls_deployed"=>0, "datapoints"=>700000, "rockets_fired"=>0, "missions_created"=>45, "mines_deployed"=>205, "st_nicks_attached"=>205,"crates_deployed"=>205)
  end

  def self.down
    Level.find(:all).each do |level|
      level.update_attributes("portals_deployed"=>0, "lightposts_deployed"=>0, "armors_donned"=>0, "portals_taken"=>0, "walls_deployed"=>0, "rockets_fired"=>0, "mines_deployed"=>0, "st_nicks_attached"=>0, "crates_deployed"=>0)
    end
  end
end
