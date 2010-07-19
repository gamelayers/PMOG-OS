require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < Test::Unit::TestCase
  fixtures :users

  # Test that the counter cache works as expected. It should increment the count for the recipient when the message
  # is first created and thus is unread.
  #
  # Once a message is marked as read, it should decrement the count and finally, if a message is marked as unread,
  # then the counter should be incremented again.
  def test_counter_cache
    recipient = users(:marc)
    sender = users(:suttree)

    assert recipient.messages.unread_count == 0

    message = Message.create( :title => "Just a test", :body => "One two, one two... this is just a test", :user => sender, :recipient => recipient)

    recipient.reload

    assert recipient.messages.unread_count == 1

    message.mark_as_read

    recipient.reload

    assert recipient.messages.unread_count == 0

    message.mark_as_unread

    recipient.reload

    assert recipient.messages.unread_count == 1
  end

end