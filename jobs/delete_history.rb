while DailyDomain.count(:conditions => {:user_id => ARGV[0]}) > 0
  User.execute( "DELETE FROM daily_domains_#{Time.now.strftime('%m_%y')} WHERE user_id = '#{ARGV[0]}' LIMIT 1000" )
end
