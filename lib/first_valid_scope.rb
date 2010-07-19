module FirstValidScope

  def self.included(base)
    base.named_scope :first_valid, lambda { |user| { :conditions => [ "id not in (SELECT dismissals.dismissable_id from dismissals WHERE dismissals.user_id = ? )", user.id ] } }

  end

end