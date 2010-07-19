class UpdateMessageCounter < ActiveRecord::Migration
  def self.up
    # The really ugly part:
    # Iterate each user, increment the counter_cache for each UNREAD message the user currently has.
    User.all do |user|
      m_count = user.messages.unread_count
      execute("update users set received_messages_count = #{m_count} where id = '#{user.id}'") 
      # user.received_messages_count = m_count
      #user.save
    end
  end

  def self.down
    # pass
  end
end
