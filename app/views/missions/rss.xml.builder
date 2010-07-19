xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title         "The Latest Missions on The Nethernet"
    xml.link          "http://thenethernet.com/missions.rss"
    xml.pubDate       CGI.rfc1123_date(@missions.first.updated_at) if @missions.any?
    xml.description   "The most recent Missions from The Nethernet"
    @missions.each do |mission|
      xml.item do
        xml.title         mission.name
        xml.link          mission_url(mission.url_name)
        xml.description   truncate(mission.description, 140, "...")
        xml.pubDate       CGI.rfc1123_date(mission.created_at)
        xml.guid          mission_url(mission.url_name)
        xml.author        mission.user.login
      end
    end
  end
end
