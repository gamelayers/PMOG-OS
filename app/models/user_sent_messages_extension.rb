# Message handling extension for user sent messages
module UserSentMessagesExtension
  # Return a +page+ of messages
  def page(page)
    paginate( :all, 
              :order => 'messages.created_at DESC',
              :page => page,
              :per_page => 10 )
  end
end