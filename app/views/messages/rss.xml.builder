xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title         "PMOG - Passively Multiplayer Online Game - #{current_user.login}'s messages"
    xml.link          host + "/users/#{current_user.login}/messages.rss"
    xml.pubDate       CGI.rfc1123_date(@messages.first.updated_at) if @messages.any?
    xml.description   "#{current_user.login}'s messages on pmog.com"
    @messages.each do |message|
      xml.item do
        xml.title         'Message from ' + message.user.login
        xml.link          host + "/users/#{current_user.login}/messages"
        xml.description   message.body
        xml.pubDate       CGI.rfc1123_date(message.created_at)
        xml.guid          host + "/users/#{current_user.login}/messages##{message.id}"
        xml.author        message.user.login
      end
    end
  end
end
