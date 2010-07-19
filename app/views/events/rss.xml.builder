xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title         "The Nethernet - Multiplayer Online Game of the Web"
    xml.link          "http://thenethernet.com/events.rss"
    xml.pubDate       CGI.rfc1123_date(@events.first.updated_at) if @events.any?
    xml.description   "Recent events from thenethernet.com"
    @events.each do |event|
      next if event.user_login.nil?
      xml.item do
        xml.title         event.user_login + " " + event.message
        xml.link          user_url(event.user_login)
        xml.description   event.user_login + " " + event.message
        xml.context       event.context
        xml.pubDate       CGI.rfc1123_date(event.created_at)
        xml.guid          event.id
        xml.author        "#{event.user_login}"
        if not event.recipient.nil?
          xml.target      "#{event.recipient.login}"
        end
      end
    end
  end
end
