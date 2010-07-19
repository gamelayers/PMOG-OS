module DailyLogInsExtension
  # Create a successful login if one doesn't already exist
  def create_unless_exists(period)
    create unless exists(period)
  end

  # Just check if we already have recorded a succesful log in for +period+  
  def exists(period)
    start_time = Date.send(period).at_beginning_of_day().to_s(:db)
    end_time = Date.send(period).end_of_day().to_s(:db)
    find( :first, :conditions => [ 'created_at >= ? AND created_at <= ?', start_time, end_time ] )
  end
end