class Action < ActiveRecord::Base
  # Because rails has poor support for the ENUM column type in ActiveRecord
  # We create this has to store the values for the context column and validate that
  # each action has a valid context.
  #
  # This should also be used to populate the select list in the html
  class ActionContext
    attr :name, :true
    
    def initialize(name)
      self.name = name
    end
  end
  
  Contexts = {
    :receive => ActionContext.new("receive"),
    :perform => ActionContext.new("perform"),
  }
  
  validates_inclusion_of :context, :in => Contexts.values.map{|i| i.name }
  
  def before_create
    self.id = create_uuid
  end
  
  def types
    Contexts.values
  end
end
