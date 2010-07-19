xml.rss('version' => '2.0') do
  xml.channel do 
    xml.title("The Nethernet: Latest Posts")
    xml.link("http://thenethernet.com/posts/latest")
    xml.description("All the latest Forums posts on The Nethernet")
    @posts.each_with_index do |post, index|
      xml.item do 
        xml.title(post.topic.title)
        xml.link(url_for(:controller => "topics", :action => "show", :forum_id => post.topic.forum.url_name, :id => post.topic.url_name, :only_path => false))
        xml.description(post.body)
        xml.pubDate(post.updated_at.rfc822)
      end
    end
  end
end
