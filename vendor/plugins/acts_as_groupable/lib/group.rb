class Group < ActiveRecord::Base
  has_many :groupables, :as => :groupable
  
  # PMOG Specific - we're using UUID primary keys
  def before_create
    self.id = create_uuid
  end
  
  # Gets all the objects that belong to the current group.
  # This expects the name of the groupable as a string with the 
  # proper casing. i.e; the model Badge extends acts_as_groupable
  # so you would provide "Badge" as the groupable_class in this method. 
  #
  # Want more verbose? group.find_by_groupable("Badge")
  # where group is an instance of the group class
  def find_all_by_groupable(groupable_class)
    # camelize the input so we can constantize it. Essentially, "badge" or "Badge" will be made into "Badge"
    # so when we constantize it, it becomes an instance of the Badge class. We can't constantize "badge" into Badge.
    camelize_class = groupable_class.camelize
    
    # Constantize it into the groupable class so we can use the find method of the class
    klass = camelize_class.constantize
    
    # Finally, find all the instances of the groupable associated with the group and return it.
    klass.find_all_by_group_id(self.id)
  end
end