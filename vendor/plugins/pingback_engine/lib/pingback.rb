require 'hpricot'
require 'open-uri'

# Encapsulates retrieving the linking article, parsing for Pingback entities
# and provides the results with getters.
class Pingback

  attr_reader :parser
  attr_reader :title, :time, :source_uri, :target_uri, :linking_node, :excerpt

  @@excerpt_length = 40
  cattr_accessor :excerpt_length


  def initialize(source_uri, target_uri)
    @source_uri = source_uri
    @target_uri = target_uri
  end

  ### FIXME: 2BRM.
  def ping; process_incoming_ping(source_uri, target_uri); end

  def receive_ping
    process_incoming_ping(source_uri, target_uri)
  end

  # For allowed return values, check http://hixie.ch/specs/pingback/pingback#return
  def process_incoming_ping(source_uri, target_uri)

    begin
      source_html = retrieve_source_content(source_uri)
      @parser     = parse(source_html)

      @time         = Time.now
      @title        = parse_title
      #return 17 unless @linking_node = find_linking_node_to(target_uri)
      #@excerpt = excerpt_content_to(@linking_node, target_uri)

      return 33 unless save_pingback # invoke the outside callback.
      return "Ping from #{source_uri} to #{target_uri} registered. Thanks for linking to us."
      ### TODO: let save_callback propagate other error codes.

    rescue SocketError, OpenURI::HTTPError => e
      return 16
    end
  end

  def retrieve_source_content(source_uri)
    return open(source_uri) if source_uri =~ /^http:\/\//
    source_uri
  end

  def parse(html)
    Hpricot(html)
  end

  def parse_title
    if elem = parser.at(:title)
      return elem.inner_html
    end

    false
  end

  def find_linking_node_to(target_uri)
    elem = (parser / :a).find do |link|
      link[:href] == target_uri
    end
  end

  ### FIXME: more cases handling needed here. this is just for the optimal case where
  ###   the referencing link is embedded in well-formed and enough text.
  def excerpt_content_to(link_node, target_uri)
    parent  = link_node.parent
    link_i  = parent.children.index(link_node)
    before  = parent.children[link_i-1]
    after   = parent.children[link_i+1]

    trim_before_text_for(before)+
      link_node.to_s+
      trim_after_text_for(after)
  end

  def trim_before_text_for(text)
    text.to_s.slice(-@@excerpt_length..-1)
  end

  def trim_after_text_for(text)
    text.to_s.slice(0..excerpt_lengthi)
  end

  def content
    "[...] #{excerpt} [...]"
  end

  def excerpt_lengthi
    @@excerpt_length-1
  end

  cattr_accessor :save_callback
  def self.save_callback &block
    @@save_callback = block
  end

  def save_pingback
    return unless @@save_callback

     @@save_callback.call(self) || true # return true.
  end

  #def reply_target_uri_does_not_accept_posts; 33; end
  def reply_target_uri_does_not_accept_posts; false; end
  def reply_target_uri_does_not_exist; 32; end
  def reply_ok; true; end

end
