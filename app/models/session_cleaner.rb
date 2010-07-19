# Ruby model, session housekeeping
class SessionCleaner < ActiveRecord::Base
  # Run this via cron to keep the sessions table in check
  # */10 * * * * ruby /full/path/to/script/runner -e production "SessionCleaner.remove_stale_sessions"
  def self.remove_stale_sessions
    timeout = 48.hours.ago.to_s(:db)
    self.connection.execute( "delete from fast_sessions where (updated_at < '#{timeout}')" )
  end
end