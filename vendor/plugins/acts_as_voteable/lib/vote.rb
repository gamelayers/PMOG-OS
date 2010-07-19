class Vote < ActiveRecord::Base

  # NOTE: Votes belong to a user
  belongs_to :user

  def self.find_votes_cast_by_user(user)
    find(:all,
      :conditions => ["user_id = ?", user.id],
      :order => "created_at DESC"
    )
  end
  
  # Added by marc@gamelayers.com on 02/11/2008 so that the ID's are consistent with our
  # current manner of indexing.
  def before_create
    self.id = create_uuid
  end
  
end