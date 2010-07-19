# CampaignMonitor
# A wrapper class to access the Campaign Monitor API. Written using the wonderful 
# Flickr interface by Scott Raymond as a guide on how to access remote web services
#
# For more information on the Campaign Monitor API, visit http://campaignmonitor.com/api
#   
# Author::    Jordan Brock <jordan@spintech.com.au>
# Copyright:: Copyright (c) 2006 Jordan Brock <jordan@spintech.com.au>
# License::   MIT <http://www.opensource.org/licenses/mit-license.php>
#
# USAGE:
#   require 'campaign_monitor'
#   cm = CampaignMonitor.new(API_KEY)     # creates a CampaignMonitor object
#                                         # Can set CAMPAIGN_MONITOR_API_KEY in environment.rb
#   cm.clients                            # Returns an array of clients associated with 
#                                         #   the user account
#   cm.campaigns(client_id)
#   cm.lists(client_id)
#   cm.add_subscriber(list_id, email, name)
#
#  CLIENT
#   client = Client.new(client_id)
#   client.lists
#   client.campaigns
#   
#  LIST
#   list = List.new(list_id)
#   list.add_subscriber(email, name)
#   list.remove_subscriber(email)
#   list.active_subscribers(date)
#   list.unsubscribed(date)
#   list.bounced(date)
#
#  CAMPAIGN
#   campaign = Campaign.new(campaign_id)
#   campaign.clicks
#   campaign.opens
#   campaign.bounces
#   campaign.unsubscribes
#   campaign.number_recipients
#   campaign.number_clicks
#   campaign.number_opens
#   campaign.number_bounces
#   campaign.number_unsubscribes
#   
#
#  SUBSCRIBER
#   subscriber = Subscriber.new(email)
#   subscriber.add(list_id)
#   subscriber.unsubscribe(list_id)
#
#  Data Types
#   SubscriberBounce
#   SubscriberClick
#   SubscriberOpen
#   SubscriberUnsubscribe
#   Result
#

require 'cgi'
require 'net/http'

class CampaignMonitor
  # Replace this API key with your own (http://www.campaignmonitor.com/api/)
  def initialize(api_key=CAMPAIGN_MONITOR_API_KEY)
    @api_key = api_key
    @host = 'http://app.campaignmonitor.com'
    @api = '/api/api.asmx/'
   end

   # Takes a CampaignMonitor API method name and set of parameters; 
   # returns an XmlSimple object with the response
  def request(method, *params)
    response = XmlSimple.xml_in(http_get(request_url(method, params)), { 'ForceArray' => false, 'ForceArray' => %r(List$|Campaign$|Subscriber$|Client$|SubscriberOpen$|SubscriberUnsubscribe$|SubscriberClick$|SubscriberBounce$), 'NoAttr' => true })
    response
  end
  
  # Takes a CampaignMonitor API method name and set of parameters; returns the correct URL for the REST API.
  def request_url(method, *params)
    url = "#{@host}#{@api}/#{method}?ApiKey=#{@api_key}"
    params[0][0].each_key do |key| url += "&#{key}=" + CGI::escape(params[0][0][key].to_s) end if params[0][0]
    url
  end
  
  # Does an HTTP GET on a given URL and returns the response body
  def http_get(url)
    Net::HTTP.get_response(URI.parse(url)).body.to_s
  end
  
  # By overriding the method_missing method, it is possible to easily support all of the methods
  # available in the API
  def method_missing(method_id, *params)
    request(method_id.id2name.gsub(/_/, '.'), params[0])
  end
  
  # Returns an array of Client objects associated with the API Key
  #
  # Example
  #  @cm = CampaignMonitor.new()
  #  @clients = @cm.clients
  #  
  #  for client in @clients
  #    puts client.name
  #  end
  def clients
    response = User_GetClients()
    unless response["Code"].to_i != 0 
      response["Client"].collect{|c| Client.new(c["ClientID"].to_i, c["Name"])}
    else
      raise response["Code"] + " - " + response["Message"]
    end
  end

  # Returns an array of Campaign objects associated with the specified Client ID
  # 
  # Example
  #  @cm = CampaignMonitor.new()
  #  @campaigns = @cm.campaigns(12345)
  #  
  #  for campaign in @campaigns
  #    puts campaign.subject
  #  end
  def campaigns(client_id)
    response = Client_GetCampaigns("ClientID" => client_id)
    unless response["Code"].to_i != 0 
      response["Campaign"].collect{|c| Campaign.new(c["CampaignID"].to_i, c["Subject"], c["SentDate"], c["TotalRecipients"].to_i)}
    else
      raise response["Code"] + " - " + response["Message"]
    end
  end
  
  # Returns an array of Subscriber Lists for the specified Client ID
  #
  # Example
  #  @cm = CampaignMonitor.new()
  #  @lists = @cm.lists(12345)
  #  
  #  for list in @lists
  #    puts list.name
  #  end
  def lists(client_id)
    response = Client_GetLists("ClientID" => client_id)
    unless response["Code"].to_i != 0 
      response["List"].collect{|l| List.new(l["ListID"].to_i, l["Name"])}
    else
      raise response["Code"] + " - " + response["Message"]
    end
  end
  
  # A quick method of adding a subscriber to a list. Returns a Result object
  #
  # Example
  #  @cm = CampaignMonitor.new()
  #  result = @cm.add_subscriber(12345, "ralph.wiggum@simpsons.net", "Ralph Wiggum")
  #  
  #  if result.code == 0
  #    puts "Subscriber Added to List"
  #  end
  def add_subscriber(list_id, email, name)
    response = Subscriber_Add("ListID" => list_id, "Email" => email, "Name" => name)
    Result.new(response["Message"], response["Code"].to_i)
  end
  
  # Provides access to the lists and campaigns associated with a client
  class Client
    attr_reader :id, :name, :cm_client
    
    # Example
    #  @client = new Client(12345)
    def initialize(id, name=nil)
      @id = id
      @name = name
      @cm_client = CampaignMonitor.new
    end
    
    # Example
    #  @client = new Client(12345)
    #  @lists = @client.lists
    #
    #  for list in @lists
    #    puts list.name
    #  end
    def lists
      response = @cm_client.Client_GetLists("ClientID" => @id)
      unless response["Code"].to_i != 0 
        response["List"].collect{|l| List.new(l["ListID"].to_i, l["Name"])}
      else
        raise response["Code"] + " - " + response["Message"]
      end
    end
    
    # Example
    #  @client = new Client(12345)
    #  @campaigns = @client.campaigns
    #
    #  for campaign in @campaigns
    #    puts campaign.subject
    #  end
    def campaigns
      response = @cm_client.Client_GetCampaigns("ClientID" => @id)
      unless response["Code"].to_i != 0 
        response["Campaign"].collect{|c| Campaign.new(c["CampaignID"].to_i, c["Subject"], c["SentDate"], c["TotalRecipients"].to_i)}
      else
        raise response["Code"] + " - " + response["Message"]
      end
    end
  end
  
  # Provides access to the subscribers and info about subscribers
  # associated with a Mailing List
  class List
    attr_reader :id, :name, :cm_client
    
    # Example
    #  @list = new List(12345)
    def initialize(id=nil, name=nil)
      @id = id
      @name = name
      @cm_client = CampaignMonitor.new
    end
    
    # Example
    #  @list = new List(12345)
    #  result = @list.add_subscriber("ralph.wiggum@simpsons.net")
    #
    #  if result.code == 0
    #    puts "Added Subscriber"
    #  end
    def add_subscriber(email, name = nil)
      response = @cm_client.Subscriber_Add("ListID" => @id, "Email" => email, "Name" => name)
      Result.new(response["Message"], response["Code"].to_i)
    end
    
    # Example
    #  @list = new List(12345)
    #  result = @list.remove_subscriber("ralph.wiggum@simpsons.net")
    #
    #  if result.code == 0
    #    puts "Deleted Subscriber"
    #  end
    def remove_subscriber(email)
      response = @cm_client.Subscriber_Unsubscribe("ListID" => @id, "Email" => email)
      Result.new(response["Message"], response["Code"].to_i)
    end
 
    # Example
    #  current_date = DateTime.new
    #  @list = new List(12345)
    #  @subscribers = @list.active_subscribers(current_date)
    #  
    #  for subscriber in @subscribers
    #    puts subscriber.email
    #  end
    def active_subscribers(date)
      response = @cm_client.Subscribers_GetActive('ListID' => @id, "Date" => date.strftime("%Y-%m-%d %H:%M:%S"))
      unless response["Code"].to_i != 0 
        response["Subscriber"].collect{|s| Subscriber.new(s["EmailAddress"], s["Name"], s["Date"])}
      else
        raise response["Code"] + " - " + response["Message"]
      end
    end
    
    # Example
    #  current_date = DateTime.new
    #  @list = new List(12345)
    #  @subscribers = @list.unsubscribed(current_date)
    #  
    #  for subscriber in @subscribers
    #    puts subscriber.email
    #  end
    def unsubscribed(date)
      response = @cm_client.Subscribers_GetUnsubscribed('ListID' => @id, 'Date' => date.strftime("%Y-%m-%d %H:%M:%S"))
      unless response["Code"].to_i != 0 
        response["Subscriber"].collect{|s| Subscriber.new(s["EmailAddress"], s["Name"], s["Date"])}
      else
        raise response["Code"] + " - " + response["Message"]
      end
    end
    
    # Example
    #  current_date = DateTime.new
    #  @list = new List(12345)
    #  @subscribers = @list.bounced(current_date)
    #  
    #  for subscriber in @subscribers
    #    puts subscriber.email
    #  end
    def bounced(date)
      response = @cm_client.Subscribers_GetBounced('ListID' => @id, 'Date' => date.strftime("%Y-%m-%d %H:%M:%S"))
      unless response["Code"].to_i != 0 
        response["Subscriber"].collect{|s| Subscriber.new(s["EmailAddress"], s["Name"], s["Date"])}
      else
        raise response["Code"] + " - " + response["Message"]
      end
    end
    
  end
  
  # Provides access to the information about a campaign
  class Campaign
    attr_reader :id, :subject, :sent_date, :total_recipients
    
    def initialize(id=nil, subject=nil, sent_date=nil, total_recipients=nil)
      @id = id
      @subject = subject
      @sent_date = sent_date
      @total_recipients = total_recipients
      @cm_client = CampaignMonitor.new
    end
    
    # Example
    #  @campaign = Campaign.new(12345)
    #  @subscriber_opens = @campaign.opens
    # 
    #  for subscriber in @subscriber_opens
    #    puts subscriber.email
    #  end
    def opens
      response = @cm_client.Campaign_GetOpens("CampaignID" => @id)
      unless response["Code"].to_i != 0 
        response["SubscriberOpen"].collect{|s| SubscriberOpen.new(s["EmailAddress"], s["ListID"].to_i, s["NumberOfOpens"])}
      else
        raise response["Code"] + " - " + response["Message"]
      end
    end
    
    # Example
    #  @campaign = Campaign.new(12345)
    #  @subscriber_bounces = @campaign.bounces
    # 
    #  for subscriber in @subscriber_bounces
    #    puts subscriber.email
    #  end
    def bounces
      response = @cm_client.Campaign_GetBounces("CampaignID"=> @id)
      unless response["Code"].to_i != 0 
        response["SubscriberBounce"].collect{|s| SubscriberBounce.new(s["EmailAddress"], s["ListID"].to_i, s["BounceType"])}
      else
        raise response["Code"] + " - " + response["Message"]
      end
    end
    
    # Example
    #  @campaign = Campaign.new(12345)
    #  @subscriber_clicks = @campaign.clicks
    # 
    #  for subscriber in @subscriber_clicks
    #    puts subscriber.email
    #  end
    def clicks
      response = @cm_client.Campaign_GetSubscriberClicks("CampaignID" => @id)
      unless response["Code"].to_i != 0 
        response["SubscriberClick"].collect{|s| SubscriberClick.new(s["EmailAddress"], s["ListID"].to_i, s["ClickedLinks"])}
      else
        raise response["Code"] + " - " + response["Message"]
      end
    end
    
    # Example
    #  @campaign = Campaign.new(12345)
    #  @subscriber_unsubscribes = @campaign.unsubscribes
    # 
    #  for subscriber in @subscriber_unsubscribes
    #    puts subscriber.email
    #  end
    def unsubscribes
      response = @cm_client.Campaign_GetUnsubscribes("CampaignID" => @id)
      unless response["Code"].to_i != 0 
        response["SubscriberUnsubscribe"].collect{|s| SubscriberUnsubscribe.new(s["EmailAddress"], s["ListID"].to_i)}
      else
        raise response["Code"] + " - " + response["Message"]
      end
    end
    
    # Example
    #  @campaign = Campaign.new(12345)
    #  puts @campaign.number_recipients
    def number_recipients
      @number_recipients.nil? ? getInfo.number_recipients : @number_recipients
    end
    
    # Example
    #  @campaign = Campaign.new(12345)
    #  puts @campaign.number_opened
    def number_opened
      @number_opened.nil? ? getInfo.number_opened : @number_opened
    end
    
    # Example
    #  @campaign = Campaign.new(12345)
    #  puts @campaign.number_clicks
    def number_clicks
      @number_clicks.nil? ? getInfo.number_clicks : @number_clicks
    end
    
    # Example
    #  @campaign = Campaign.new(12345)
    #  puts @campaign.number_unsubscribed
    def number_unsubscribed
      @number_unsubscribed.nil? ? getInfo.number_unsubscribed : @number_unsubscribed
    end
    
    # Example
    #  @campaign = Campaign.new(12345)
    #  puts @campaign.number_bounced
    def number_bounced
      @number_bounced.nil? ? getInfo.number_bounced : @number_bounced
    end
    
    private
      def getInfo
        info = @cm_client.Campaign_GetSummary('CampaignID'=>@id)
        @title = info['title']
        @number_recipients = info["Recipients"].to_i
        @number_opened = info["TotalOpened"].to_i
        @number_clicks = info["Click"].to_i
        @number_unsubscribed = info["Unsubscribed"].to_i
        @number_bounced = info["Bounced"].to_i
        self
      end
  end
  
  # Provides the ability to add/remove subscribers from a list
  class Subscriber
    attr_accessor :email_address, :name, :date_subscribed  
    
    def initialize(email_address, name=nil, date=nil)
      @email_address = email_address
      @name = name
      @date_subscribed = date_subscribed
      @cm_client = CampaignMonitor.new
    end
    
    # Example
    #  @subscriber = Subscriber.new("ralph.wiggum@simpsons.net")
    #  @subscriber.add(12345)
    def add(list_id)
      response = @cm_client.Subscriber_Add("ListID" => list_id, "Email" => @email_address, "Name" => @name)
      Result.new(response["Message"], response["Code"].to_i)
    end
    
    # Example
    #  @subscriber = Subscriber.new("ralph.wiggum@simpsons.net")
    #  @subscriber.add_and_resubscribe(12345)
    def add_and_resubscribe(list_id)
      response = @cm_client.Subscriber_AddAndResubscribe("ListID" => list_id, "Email" => @email_address, "Name" => @name)
      Result.new(response["Message"], response["Code"].to_i)
    end
    
    # Example
    #  @subscriber = Subscriber.new("ralph.wiggum@simpsons.net")
    #  @subscriber.unsubscribe(12345)
    def unsubscribe(list_id)
      response = @cm_client.Subscriber_Unsubscribe("ListID" => list_id, "Email" => @email_address)
      Result.new(response["Message"], response["Code"].to_i)
    end
  end
  
  # Encapsulates 
  class SubscriberBounce
    attr_reader :email_address, :bounce_type, :list_id
    
    def initialize(email_address, list_id, bounce_type)
      @email_address = email_address
      @bounce_type = bounce_type
      @list_id = list_id
    end
  end
  
  # Encapsulates 
  class SubscriberOpen
    attr_reader :email_address, :list_id, :opens
    
    def initialize(email_address, list_id, opens)
      @email_address = email_address
      @list_id = list_id
      @opens = opens
    end
  end
  
  # Encapsulates 
  class SubscriberClick
    attr_reader :email_address, :list_id, :clicked_links
    
    def initialize(email_address, list_id, clicked_links)
      @email_address = email_address
      @list_id = list_id
      @clicked_links = clicked_links
    end
  end
  
  # Encapsulates 
  class SubscriberUnsubscribe
    attr_reader :email_address, :list_id
    
    def initialize(email_address, list_id)
      @email_address = email_address
      @list_id = list_id
    end
  end
  
  # Encapsulates the response received from the CampaignMonitor webservice.
  class Result
    attr_reader :message, :code
    
    def initialize(message, code)
      @message = message
      @code = code
    end
  end
end