xml.rss('version' => '2.0') do
  xml.channel do 
    xml.title(@topic.forum.title)
    xml.link(forum_topics_url)
    xml.description(@topic.title)
    @topic.posts.each_with_index do |post, index|
      xml.item do 
        xml.title(@topic.title)
        xml.link(forum_topic_url(@topic, :anchor => 'post_' + index.to_s, :only_path => false))
        xml.description(post.body)
        xml.pubDate(post.updated_at.rfc822)
      end
    end
  end
end