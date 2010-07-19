class PruneLocations
  def self.prune_it(sleepy=nil)
        min_date = Location.minimum(:created_at).yesterday.yesterday # just to be sure
        end_date = Time.now.tomorrow.tomorrow

        puts "#{min_date} => #{end_date}"

        while min_date <= end_date do
                puts "CURRENT_DATE #{min_date.to_s(:db)}"
                max_date = min_date + 2.hour # do in 2 hour intervals

                locs = Location.find(:all, :conditions => ["created_at >= ? and created_at < ?", min_date, max_date])

                locs.each do |old|
                   Location.delete(old.id) if !old.is_interesting?
                end

                min_date = max_date
                sleep(sleepy) if !sleepy.nil? and sleepy > 0
        end
  end
end
