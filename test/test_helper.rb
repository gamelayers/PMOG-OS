ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
#require 'ruby-debug'

begin
  require 'redgreen'
  require 'turn'
rescue LoadError
  nil
end

require File.expand_path(File.dirname(__FILE__) + '/helper_testcase')

class Test::Unit::TestCase
  include AuthenticatedTestHelper
  include Arts

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  ApplicationHelper.module_eval do
    # Development and Production expect this method to be defined so we mock it
    # here instead of adding test logic to the main application.
    def host
      'http://test.pmog.com'
    end
  end

  def self.all_fixtures
    fixtures Dir[File.join( File.dirname( __FILE__ ), 'fixtures', '*.yml' )].collect { |f| File.basename( f, ".yml" ) }
  end

  def follow_redirect_with_restful_routes
    #use the normal one unless its a string
    return follow_redirect_without_restful_routes unless @response.redirected_to.is_a?(String)
    #okay we need to follow the redirect, but first parse the path
    url = URI.parse(@response.redirected_to)

    path = url.path

    extras = url.query.nil?? {} : CGI.parse(url.query)

    #parse puts values into array so flatten
    extras.each do |key, value|
      extras[key] = value[0] if value.is_a?(Array) && value.length == 1
    end


    # Assume given controller
    request = ActionController::TestRequest.new({}, {}, nil)
    request.env["REQUEST_METHOD"] = "GET"
    request.path = path

    redirected_controller = ActionController::Routing::Routes.recognize(request)

    if @controller.is_a?(redirected_controller)
      #then we can redirect, otherwise we can't'
      get request.path_parameters[:action], extras.symbolize_keys!
    else
      raise "Can't follow redirects outside of current controller (from #{@controller.controller_name} to #{redirected_controller})"
    end
  end

  alias_method_chain :follow_redirect, :restful_routes

  # Add more helper methods to be used by all tests here...
  def ready_user(user = nil)
    if user.nil?
      user = users(:suttree)
    else
      @user = user
    end
    @request.cookies["auth_token"] = CGI::Cookie.new( 'name' => 'auth_token', 'value' => user.remember_token )
  end

  def login
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    post :create, :login => 'pmog', :password => 'itsasekrit'

    follow_redirect

    assert session[:user]

    get '/users/pmog'
  end

  def logout
    get '/sessions/destroy'
    assert session[:user].nil?
    assert_response :redirect
    assert_redirected_to '/'
    follow_redirect!
  end

  # Fake the track controller into thinking the url has a mine
  def plant_mine_on(url = 'http://www.foo.com')
    @controller.class.class_eval { @@sekret_url = url }
    @controller.instance_eval do
      def track_location(url)
        @location = Location.create(:url => @@sekret_url)
        @mine     = Mine.create(:location => @location, :user_id => current_user.id)
        @location
      end
    end
  end

#    post :create, :format => "json", :location_id => @location.id, :portal => { :destination => @location.url, :title => 'my portal', :nsfw => 'false' }

  def response_to_json
    ActiveSupport::JSON.decode(@response.body)
  end

  def add_tools(user)
    # Initialize user preferences with the default.
    user.init_preferences

    # Your reward for joining -10 of each tool, 5 mission starter kits
    # and 200 DP in a crate on their profile page
    Tool.cached_multi.each do |tool|
      user.inventory.deposit tool.url_name.to_sym, 10 unless tool.url_name == 'watchdogs' || tool.url_name == 'grenades' || tool.url_name == 'crates' || tool.url_name = 'skeleton_keys'
    end

    # Starter kits are 4 lightposts and 3 portals
    5.times do
      user.inventory.deposit :lightposts, 4
      user.inventory.deposit :portals, 3
    end

    user.reward_datapoints(200, false)
  end

  # Add more helper methods to be used by all tests here...
  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end

  def assert_no_difference(object, method = nil, &block)
    assert_difference object, method, 0, &block
  end

  def assert_changed(object, method = nil)
    initial_value = object.send(method)
    yield
    assert initial_value != object.reload.send(method), "#{object}##{method} should not be equal"
  end

  def assert_unchanged(object, method = nil, &block)
    initial_value = object.send(method)
    yield
    assert_equal initial_value, object.reload.send(method), "#{object}##{method} should be equal"
  end

  # From http://zentest.rubyforge.org/ZenTest/classes/Test/Unit/Assertions.src/M000161.html
  def assert_include(item, obj, message = nil)
    assert_respond_to obj, :include?
    message ||= "#{obj.inspect}\ndoes not include\n#{item.inspect}."
    assert_block message do obj.include? item end
  end

  # Authorize a user.
  def authorize(user)
    @request.session[:user_id] = user.id
  end
end
