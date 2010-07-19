module Mixins; module Vote; end; end;
module Mixins::Vote::Voteable
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods

  end
end
Vote.send :include, Mixins::Vote::Voteable