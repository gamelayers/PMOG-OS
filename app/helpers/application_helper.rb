module ApplicationHelper
  include AvatarHelper

  # Makes a unique body tag id
  def bodytag_id
    controller.class.to_s.underscore.gsub(/_controller$/, '')
  end

  def bodytag_class
    controller.action_name.underscore
  end

  # Get the application version
  def version
    #Deploy.version
    APP_VERSION.to_s
  end

  # Get the date of the revision
  def revision_date
    APP_VERSION.build_date
  end

  # Show the local time
  def tz(time_at)
    TzTime.zone.utc_to_local(time_at.utc)
  end

  # Create a new UUID string
  def create_uuid
    UUID.timestamp_create().to_s
  end

  def render_date_time(datetime)
    datetime.strftime("%d %b %Y %H:%M:%S")
  end

  # Generic helper for displaying user-entered data. Truncates all links
  # to +link_length+ length
  def format(text, link_length = 35)
    auto_link( simple_format( white_list( text ) ) ) do |text|
      truncate(text, link_length)
    end
  end

  # Remove your login name from the start of any message
  def strip_message_recipient(text)
    text.sub( /@(#{current_user.login})/i, '' )
  end

  # Auto links logins in message body, unused for now
  def auto_link_message_logins(text)
    text.gsub( /@(\w*)/i, '<a href=\'http://thenethernet.com/users/\1\'>\1</a>' )
  end

  # User admin status
  def site_admin?
    # The caching here is messing up the display of the admin tab on new user profiles. Gonna
    # nix it for now, until suttree can take a look.
    #(logged_in? and current_user.caches(:has_role?, :with => 'site_admin', :ttl => 1.week))
    (logged_in? and current_user.has_role?('site_admin'))
  end

  # User 'steward' status
  def steward?
    # The caching here is messing up the display of the admin tab on new user profiles. Gonna
    # nix it for now, until suttree can take a look.
    #(logged_in? and current_user.caches(:has_role?, :with => 'steward', :ttl => 1.week))
    (logged_in? and current_user.has_role?('steward'))
  end

  def user_is?(rolename)
    unless instance_variable_defined?("@"+rolename)
      instance_variable_set("@"+rolename, (logged_in? and current_user.caches(:has_role?, :with => rolename)))
    end
  end

  # Dsplay the user login and link to their profile page
  def link_to_user(options)
    return false if options.empty? or options[:user].nil?

    options = { :include_meta_data => true, :only_path => true }.merge(options)
    ret = link_to( h(options[:user].login), user_path(options[:user], :only_path => options[:only_path] ) )
    ret += ' &raquo; Level ' + options[:user].current_level.to_s + ' ' + options[:user].primary_association.to_s if options[:include_meta_data]
    ret += ' &raquo; ' + options[:user].datapoints.to_s + ' DP' if options[:include_meta_data]
    ret
  end

  # Shortens a string, whilst respecting breaking word boundaries
  # From - http://snippets.dzone.com/posts/show/4578
  def shorten(string, count = 30)
    if string.length >= count
      shortened = string[0, count]
      splitted = shortened.split(/\s/)
      words = splitted.length
      splitted[0, words-1].join(" ") + ' ...'
    else
      string
    end
  end

  def tag_cloud(tags, classes)
    max, min = 0, 0
    tags.each do |tag|
      max = tag.count if tag.count > max
      min = tag.count if tag.count < min
    end

    divisor = ((max - min) / classes.size) + 1
    tags.each do |tag|
      yield tag, classes[(tag.count - min) / divisor]
    end
  end

  def get_link_to(object, type)
    case type
      when "mission"   then link_to(object.name, mission_path(object), :rel => 'tag')
      when "lightpost" then link_to(object.location.url, object.location.url, :rel => 'tag')
      when "user"      then link_to(object.login, user_path(object.login), :rel => 'tag')
    end
  end

  # The full host including the port. Note that we don't
  # want to reveal the use of ext.pmog.com in the overlays
  # so we have a rewrite for that.
  def host
    if request.env[ 'HTTP_HOST' ] =~ /ext.pmog.com/ || request.env[ 'HTTP_HOST' ] =~ /ext.thenethernet.com/
      return 'http://thenethernet.com'
    else
      return 'http://' + request.env[ 'HTTP_HOST' ] rescue 'http://localhost:3000'
    end
  end

  # The slice name we're running on
  def current_slice
    @current_slice ||= `uname -n`.strip rescue nil
  end

  # A helper to build an in-place select box editor
  def in_place_select_editor(field_id, options = {})
    function =  "new Ajax.InPlaceSelectEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"
    function << (', ' + options_for_javascript(
    {
      'selectOptionsHTML' =>
      %('#{escape_javascript(options[:select_options].gsub(/\n/, ""))}')
    }
    )
    ) if options[:select_options]
    function << ')'
    javascript_tag(function)
  end

  # The in-place select box editor field
  # An extension of the in_place_editor_field
  # Of special note is the item_id parameter of this method. It's needed to build the
  # editorId parameter that we use to get the ID of the item being edited. It's needed
  # because we use UUID's as table indexes. See badges_controller.rb#list comments for
  # more details
  def in_place_select_editor_field(object, method, display, item_id, tag_options = {},
    in_place_editor_options = {})
    tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = { :tag => "span",
      :id => "#{object}_#{method}_#{item_id}_in_place_editor",
      :class => "in_place_editor_field"}.merge!(tag_options)
    in_place_editor_options[:url] =
    in_place_editor_options[:url] ||
    url_for({ :action => "set_#{object}_#{method}"})
    tag.to_content_tag_display(tag_options.delete(:tag), display, tag_options) +
    in_place_select_editor(tag_options[:id], in_place_editor_options)
  end

end

def text_field_for(form, field,
                   size=HTML_TEXT_FIELD_SIZE,
                   maxlength=DB_STRING_MAX_LENGTH)
  label = content_tag("label", "#{field.humanize}:", :for => field)
  form_field = form.text_field field, :size => size, :maxlength => maxlength, :class => 'input'
  content_tag("div", "#{label} #{form_field}", :class => "form_row")
end

# Used to parse the different grammatical strings from an event message
EVENT_REGEX = Regexp.new('\[(.*)\|(.*)\]')

# Shows the proper event message depending on who is looking at the message
def show_event(event)
  # First assign the results of the regex matching to a variable
  match = EVENT_REGEX.match(event.message)

  # Initialize the variable that we'll eventually display
  message = nil

  # Check if the current user is the same as the originator of the event
  if logged_in? and event.user_id == current_user.id
    message = event.message
    message = message.gsub('was', 'were')
    message = message.gsub('their', 'your')
    message = "You " + message
    # # If it is and the regex matched the string
    #     if match
    #       # Replace the entire matched string with just the portion specific to the originator
    #       # since the originator and the current user are the same.
    #       message = event.message.gsub(match[0], match[1])
    #     else
    #       # If the regex doesn't match it means the event message doesn't contain the pattern
    #       # so we'll just show the message with the You prepended
    #       message = "You " + event.message
    #     end
  # If the current user and the event originator are not the same
  else
    # If the message matches the pattern...
    if match
      # The message pattern should have a <user login><space><modifier> i.e. marc has, marc was etc;
      # Split on the <space> to get the user login and the modifier
      user = match[2].split(" ")
      # Replace the entire matched string with just the subsection but turn the user login to a link to the users profile
      #message = event.message.gsub(match[0], link_to(user[0], user_path(User.caches(:find_by_login, :with => user[0], :ttl => 1.day))) + " " + user[1])
      message = event.message.gsub(match[0], link_to(user[0], '/users/' + user[0]) + " " + user[1])
    else
      if event.user.nil?
        message = 'somebody' + event.message # this happens from time to time...
      else
        # Otherwise the message doesn't follow the pattern and we should link to the user and append the message.
        message = link_to( h(event.user_login), '/users/' + event.user_login) + ' ' + event.message
      end
    end
  end
  # Finally, return the message
  #return message.gsub(/<\/?[^>]*>/, "") + ' ' + time_ago_in_words(event.created_at) + " ago"
  return message + ' ' + time_ago_in_words(event.created_at) + " ago"
end

def dp_icon
  "<a href=\"/guide/rules/datapoints/\"><img src=\"/images/shared/icons/datapoint-16.png\" alt=\"datapoints icon\" title=\"Datapoints\" border=\"0\" width=\"16\" height=\"16\" valign=\"center\" class=\"icon16\" /></a>"
end

def ping_icon
  "<a href=\"/guide/rules/pings/\"><img src=\"/images/shared/icons/ping-16.png\" alt=\"pings icon\" title=\"Pings\" border=\"0\" width=\"16\" height=\"16\" valign=\"center\" class=\"icon16\" /></a>"
end

def cp_icon
  "<a href=\"/guide/rules/classpoints/\"><img src=\"/images/shared/icons/classpoint-16.png\" alt=\"classpoints icon\" title=\"Classpoints\" border=\"0\" width=\"16\" height=\"16\" valign=\"center\" class=\"icon16\" /></a>"
end

# Tags to aid in a near seamless integration of the google ajax library
def google_loader_tag
  "<script type=\"text/javascript\" src=\"http://www.google.com/jsapi\"></script>"
end

def google_prototype_tag
  google_tag('prototype', '1.6.0.2')
end

def google_scriptaculous_tag
  google_tag('scriptaculous', '1.8.1')
end

def nice_print(dt)
  return '' if dt.nil?
  dt.strftime("%b %d, %Y")
end

def error_handling_form_for(record_or_name_or_array, *args, &proc)
  options = args.detect { |argument| argument.is_a?(Hash) }
  if options.nil?
    options = {:builder => ErrorHandlingFormBuilder}
    args << options
  end
  options[:builder] = ErrorHandlingFormBuilder unless options.nil?
  form_for(record_or_name_or_array, *args, &proc)
end

def remote_error_handling_form_for(record_or_name_or_array, *args, &proc)
  options = args.detect { |argument| argument.is_a?(Hash) }
  if options.nil?
    options = {:builder => ErrorHandlingFormBuilder}
    args << options
  end
  options[:builder] = ErrorHandlingFormBuilder unless options.nil?
  remote_form_for(record_or_name_or_array, *args, &proc)
end

# Extending the ActionView::Helpers::InstanceTag class to help us build the in-place select editor
module ActionView
  module Helpers
    class InstanceTag #:nodoc:
      include Helpers::TagHelper
      def to_content_tag_display(tag_name, display, options = {})
        content_tag(tag_name, display, options)
      end
    end
  end
end

private
# Used to build the links to the google hosted ajax libraries
def google_tag(name, version)
  "<script type=\"text/javascript\">google.load(\"#{name}\", \"#{version}\");</script>"
end
