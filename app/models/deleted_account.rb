# == Schema Information
# Schema version: 20081220201004
#
# Table name: deleted_accounts
#
#  id            :string(36)    not null, primary key
#  user_id       :string(36)    not null
#  deleted_id    :string(36)    not null
#  deleted_login :string(255)   
#  user_ip       :string(255)   
#  created_at    :datetime      
#  updated_at    :datetime      
#

class DeletedAccount < ActiveRecord::Base
  
  def before_create
    self.id = create_uuid
  end
  
end
