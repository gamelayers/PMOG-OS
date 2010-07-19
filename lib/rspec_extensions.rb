module ActiveRecordMatchers
  class HaveValidAssociations
    def matches?(model)
      @failed_association = nil
      @model_class = model.class
      
      model.class.reflect_on_all_associations.each do |assoc|
        model.send(assoc.name, true) rescue @failed_association = assoc.name
      end
      !@failed_association
    end
  
    def failure_message
      "invalid association \"#{@failed_association}\" on #{@model_class}"
    end
  end

  def have_valid_associations
    HaveValidAssociations.new
  end
end