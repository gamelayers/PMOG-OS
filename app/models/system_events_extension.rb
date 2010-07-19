module SystemEventsExtension

  # 10 most recent system events. Includes both read and unread
  def most_recent
    find(:all, :limit => 10)
  end

  # 10 most recent unread messages.
  def most_recent_unread
    find(:all, :conditions => ['created_at > ? AND read_at IS NULL', 1.week.ago], :limit => 10)
  end

  # Total number of unread messages.
  def unread_count
    count(:all, :conditions => ['created_at > ? AND read_at IS NULL', 1.week.ago])
  end

  def mark_unread_read
    events = find(:all, :conditions => ['created_at > ? AND read_at IS NULL', 1.week.ago])
    events.each do |e|
      e.read!
    end

    return true
  end

end
