# Message handling extension for user messages
module UserMessagesExtension
  # Returns the latest unread +message+ for display in the extension. If there are no unread messages
  # it returns the latest +read+ message. This is useful in conjunction with condition GET as it allows
  # us to send a sensible +last_modified+ timestamp to the extension.
  def latest
    proxy_owner.get_cache( 'latest_messages', :ttl => 1.week ) {
      latest = find(:first, :from => "messages", :conditions => {:read_at => nil}, :order => "created_at ASC")
      latest = find( :first, :from => "messages", :order => 'messages.created_at DESC', :limit => 1 ) if latest.nil?
      latest
    }
  end

  def latest_pmog
    proxy_owner.get_cache( 'latest_pmog_message', :ttl => 1.day ) {
      tehpmog = User.find_by_login 'pmog'
      find( :first, :include => [ :user, :recipient ],
        :conditions => ['user_id = ?', tehpmog.id],
        :order => 'messages.created_at DESC', :limit => 1
      )
    }
  end

  # Return a +page+ of messages
  def page(page)
    paginate_by_sql(
      ['SELECT * FROM messages WHERE (messages.recipient_id = ? AND (syndication_id IS NULL)) ORDER BY messages.created_at DESC', proxy_owner.id],
      :page => page,
      :per_page => 50
    )
  end

  # List all read +messages+
  def read(limit = nil)
    proxy_owner.get_cache( "read_messages_#{limit}", :ttl => 1.day ) {
      if limit
        find( :all, :conditions => [ 'read_at IS NOT NULL' ], :include => [ :user, :recipient ], :order => 'messages.created_at ASC', :limit => limit )
      else
        find( :all, :conditions => [ 'read_at IS NOT NULL' ], :order => 'messages.created_at ASC' )
      end
    }
  end

  # List all unread +messages+
  def unread(limit = nil)
    proxy_owner.get_cache( "unread_messages_#{limit}", :ttl => 1.day ) {
      if limit
        find( :all, :conditions => { :read_at => nil }, :include => [ :user, :recipient ], :order => 'messages.created_at ASC', :limit => limit )
      else
        find( :all, :conditions => { :read_at => nil }, :order => 'messages.created_at ASC' )
      end
    }
  end

  # The number of +messages+ that are unread. Used in the header of the layout
  def unread_count
    #proxy_owner.received_messages_count
    # Commenting out the section below because we now have a counter cache.
    # It's easier to change this method to return the counter_cache value
    # rather than replace all references to this method.
     proxy_owner.get_cache( 'unread_count', :ttl => 1.week ) {
       count( :all, :conditions => { :read_at => nil } )
     }
  end

  # Quick way of marking all messages as read, *then* clearing the cache
  def mark_all_as_read
    execute( "UPDATE messages SET read_at = NOW() WHERE user_id = '#{proxy_owner.id}' AND read_at IS NULL" )
    execute( "UPDATE user set received_messages_count = 0 where user_id = '#{proxy_owner.id}'" )
    clear_cache()
  end

  # Quick way of marking a collection of messages as read, and *then* clear the unread count cache
  def mark_these_as_read(messages)
    unread = messages.collect{ |m| m.unread? }.any?
    messages.each { |m| m.mark_as_read }
    ##messages.collect{ |m| execute( "UPDATE messages SET read_at = NOW() WHERE id = '#{m.id}'" ) unless m.read? }
    clear_cache if unread
  end

  # Clear out the message cache, used when someone has sent you a message. Note that we hard code
  # the limit to 10 as this is the amount we page on the site. It's a hack, sorry :(
  def clear_cache
    limit = 10
    proxy_owner.expire_cache( 'latest_messages' )
    proxy_owner.expire_cache( 'latest_pmog_messages' )
    proxy_owner.expire_cache( "read_messages_#{limit}" )
    proxy_owner.expire_cache( "unread_messages_#{limit}" )
    proxy_owner.expire_cache( 'unread_count' )
  end
end
