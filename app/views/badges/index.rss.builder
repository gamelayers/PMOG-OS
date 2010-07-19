xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title         "#{@user.login}'s Badges on The Nethernet"
    xml.link          "http://thenethernet.com/users/#{@user.login}/badges.rss"
    xml.pubDate       CGI.rfc1123_date(@user.badges.first.updated_at) if @user.badges.any?
    xml.description   "Earned badges on The Nethernet"
    @user.badges.each do |badge|
      xml.item do
        xml.title         badge.name
        xml.link          "http://thenethernet.com/guide/badges/#{badge.url_name}"
        xml.description   badge.description
        xml.pubDate       CGI.rfc1123_date(badge.created_at)
        xml.guid          badge.id
        xml.author        "#{@user.login}"
      end
    end
  end
end
