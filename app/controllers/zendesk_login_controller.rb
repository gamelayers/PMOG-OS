class ZendeskLoginController < ApplicationController
  before_filter :login_required

  MAGIC_ZENDESK_TOKEN = "8ZOH7pWFJihieS5KqoAWQbPv7t13QH41ZJVbKBu7dyffISBZ".freeze

  # GET /track.js?url=abc
  # Returns a JSON description of the url and any associated missions, events, users, etc.
  def index
    redirect_to "/" and return unless logged_in?

    #name = "#{current_user.forename} #{current_user.surname}".strip
    name = current_user.email.strip # if name.nil? || name.length < 2
    external_id = current_user.login.strip
    ts = Time.now.to_i.to_s
    email = current_user.email.strip
    organization = "GameLayers"

    name.downcase!
    external_id.downcase!
    organization.downcase!
    email.downcase!

    # hexdigest(MD5(name+email+external_id+organization+token+timestamp))
    hash = Digest::MD5.hexdigest(name+email+external_id+organization+MAGIC_ZENDESK_TOKEN+ts)

    name = CGI::escape(name)
    external_id = CGI::escape(external_id)
    organization = CGI::escape(organization)
    email = CGI::escape(email)


    #params = URI::escape("name=#{name}&email=#{email}&timestamp=#{ts}&external_id=#{external_id}&organization=#{organization}&hash=#{hash}")
    params = "name=#{name}&email=#{email}&timestamp=#{ts}&external_id=#{external_id}&organization=#{organization}&hash=#{hash}"
    #puts "+++++ "
    #puts params
    #puts "+++++"

    zendesk_url = "http://support.thenethernet.com/access/remote/?#{params}"
    #puts "********"
    #puts "ZENDESK #{zendesk_url}"
    #puts "********"

    redirect_to zendesk_url
  end

  def logout
    redirect_to "/"
  end

end
