module Mixins; module Comment; end; end;
module Mixins::Comment::Validateable
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def per_page
      10
    end
  end
end
Comment.send :include, Mixins::Comment::Validateable

# Validates that the comment isn't empty
Comment.send :validates_presence_of, :comment
