class Tagging < ActiveRecord::Base #:nodoc:
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  
  def before_create
    self.id = create_uuid
  end
  
  def after_destroy
    if Tag.destroy_unused
      if tag.taggings.count.zero?
        tag.destroy
      end
    end
  end
end
