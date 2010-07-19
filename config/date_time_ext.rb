ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :default => "%m/%d/%Y",
  :short => "%d %B %Y",
  :date_time12 => "%m/%d/%Y %I:%M%p",
  :date_time24 => "%m/%d/%Y %H:%M"
)

# From DZone snippets, usage: Time.now.to_google_s
class Time
  def to_google_s
    if Time.now.beginning_of_day <= self
      self.hour.to_s + ":" + self.min.to_s + " " + self.strftime('%p').downcase
    elsif Time.now.beginning_of_year <= self
      self.strftime('%b ') + self.day.to_s
    else
      self.month.to_s + '/' + self.day.to_s + '/' + self.strftime('%y')
    end
  end
end