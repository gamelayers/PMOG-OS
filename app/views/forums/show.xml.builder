xml.rss('version' => '2.0') do
  xml.channel do 
    xml.title(@forum.title)
    xml.link(forums_url)
    xml.description(@forum.title)
    @forum.topics.each_with_index do |topic, index|
      xml.item do 
        xml.title(topic.title)
        xml.link(forum_topic_url(topic))
        xml.description(topic.description)
        xml.pubDate(topic.updated_at.rfc822)
      end
    end
  end
end