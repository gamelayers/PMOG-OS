# Rails model, for cron related activities. Trigger with commands like...
# @daily ruby /var/www/pmog/current/script/runner Cron.wipe_exceptions -e production >> /dev/null 2>&1
class Cron < ActiveRecord::Base
  set_table_name 'users'

  # Clean up logged exceptions
  def self.wipe_exceptions
    Cron.execute( 'delete from logged_exceptions' )
  end
  
  # Clean up archived Bj's
  def self.wipe_bj_archives
    Cron.execute( "delete from bj_job_archive" )
  end

  # Clean up completed Bj's
  def self.wipe_finished_bjs
    Cron.execute( "delete from bj_job where state = 'finished'" )
  end

  # Clean up old sessions
  # - after 1 week, sessions are considered to have expired
  def self.wipe_expired_sessions
    CGI::Session::ActiveRecordStore::FastSessions.delete_old!
  end

  # Award badges to each active user, via Bj
  def self.badges
    Bj.submit "./script/runner ./jobs/badges.rb", :rails_env => 'cron', :env => 'cron', :tag => "badges", :priority => -50
  end

  # Move old daily_domains records to a date-stamped table, e.g daily_domains_03_09
  # See jobs/archive_daily_domains.rb for more information
  # Deprecated, takes forever to run - 11/04/09
  #def self.archive_daily_domains
  #  Bj.submit "./script/runner ./jobs/archive_daily_domains.rb", :rails_env => 'cron', :env => 'cron', :tag => "archive_daily_domains", :priority => 0
  #end

  # Gets the total user count and confirmed acquaintances count and stores them in the database for use in a graph for tracking
  # average acquaintances per user.
  # Deprecated - 02/03/09
  #def self.user_acquaintance_stats
  #  Bj.submit "./script/runner ./jobs/user_acquaintances_stats.rb", :rails_env => 'cron', :env => 'cron', :tag => "user_acquaintance_stats", :priority => -20
  #end

  # The migration was too slow, so this is a background job to create the larger sized profile assets
  # - see db/migrate/20090212150719_create_profile_assets.rb
  def self.create_profile_assets
    Bj.submit "./script/runner ./jobs/create_profile_assets.rb", :rails_env => 'cron', :env => 'cron', :tag => "create_profile_assets", :priority => -30
  end

  # Give everyone who played PMOG a badge now that we're TheNethernet
  def self.pmog_badge
    Bj.submit "./script/runner ./jobs/pmog_badge.rb", :rails_env => 'cron', :env => 'cron', :tag => "pmog_badge", :priority => -60
  end

  # Push background tasks to BJ for processing, runs from cron on staging:
  # (cd /data/pmog/current; script/runner Cron.submit_bj_tasks -e production)
  def self.submit_bj_tasks
    Bj.submit './script/runner Cron.wipe_finished_bjs', :rails_env => 'cron', :env => 'cron', :tag => 'wipe_finished_bjs'
    Bj.submit './script/runner Cron.wipe_exceptions', :rails_env => 'cron', :env => 'cron', :tag => 'wipe_exceptions'
    Bj.submit './script/runner Cron.wipe_expired_sessions', :rails_env => 'cron', :env => 'cron', :tag => 'wipe_sessions'
    Bj.submit './script/runner Cron.wipe_bj_archives', :rails_env => 'cron', :env => 'cron', :tag => 'wipe_bj_archives'

    Bj.submit './script/runner Cron.badges', :rails_env => 'cron', :env => 'cron', :tag => 'badges'

    Bj.submit './script/runner DailyDomain.top_domains', :rails_env => 'cron', :env => 'cron', :tag => 'top_domains'
    Bj.submit './script/runner DailyDomain.create_partition_table', :rails_env => 'cron', :env => 'cron', :tag => 'create_daily_domains_partition_table'
    #Bj.submit './script/runner Stat.prepare_all', :rails_env => 'cron', :env => 'cron', :tag => 'stats'
    Bj.submit './script/runner DailyClasspoints.generate_todays_events', :rails_env => 'cron', :env => 'cron', :tag => 'leaderboard_events'

    Bj.submit './script/runner AbilityStatus.reset_daily_invite_buffs', :rails_env => 'cron', :env => 'cron', :tag => 'daily_invite_buffs'
  end
  
  # If we submit a job to Bj from production, it will start to process them
  # on the production servers. We DO NOT want this to happen, so this wrapper
  # allows us to submit a job to the Bj queue on *staging*, leaving production alone
  def self.submit_bj_task_from_production(task, tag, priority = -20)
    state = "pending"
    is_restartable = true
    submitter = Bj.hostname
    submitted_at = Time.now
    env = 'cron'
    sql = "INSERT INTO bj_job (command, state, priority, tag, env, is_restartable, submitter, submitted_at ) VALUES ( '#{task}', '#{state}', '#{priority}', '#{tag}', '#{env}', '#{is_restartable}', '#{submitter}', '#{submitted_at}' )"
    ActiveRecord::Base.connection.insert(sql)
  end

  # Award all the alpha badges
  def self.alpha_badges
    return "Deprecated now that PMOG has left Beta"
    Bj.submit "./script/runner ./jobs/alpha_badges.rb", :rails_env => 'cron', :env => 'cron', :tag => "alpha_badges", :priority => -20
  end

  # Award all the beta badges
  def self.beta_badges
    return "Deprecated now that PMOG has left Beta"
    Bj.submit "./script/runner ./jobs/beta_badges.rb", :rails_env => 'cron', :env => 'cron', :tag => "beta_badges", :priority => -20
  end

  # Generate invite keys so that users can invite friends
  def self.generate_beta_keys
    Bj.submit "./script/runner ./jobs/generate_beta_keys.rb", :rails_env => 'cron', :env => 'cron', :tag => "beta_badges", :priority => -30
  end
  
  # Send beta invites in batches of 2000 a day
  def self.beta_invites
    return "Deprecated now that PMOG has left Beta"
    sql = 'select * from beta_users where emailed = 0 and beta_key_id is null group by email order by created_at asc limit 2000'
    BetaUser.find_by_sql( sql ).collect{ |u| Bj.submit "./script/runner ./jobs/invites.rb #{u.email}", :rails_env => 'cron', :env => 'cron', :tag => "invite_#{u.email}", :priority => -15 }
  end
end
