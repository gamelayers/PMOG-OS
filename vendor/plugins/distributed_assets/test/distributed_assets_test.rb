RAILS_ENV = 'test'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'action_controller/test_process'
require 'breakpoint'

class StubController < ActionController::Base
  def rescue_action(e) raise e end;
  attr_accessor :request, :url
end

class DistributedAssetsTest < Test::Unit::TestCase
  include ActionView::Helpers::AssetTagHelper
  
  def setup
    @request    = ActionController::TestRequest.new
    @controller = StubController.new
    @controller.request = @request
    
    multiple_hosts!
  end
  
  def test_should_return_image_tag_with_single_asset_host
    single_host!
    assert_match %r{<img alt="Myimg" src="http://assets.domain.com/images/myimg.jpg(\?\d*)?" />},
      image_tag('myimg.jpg')
  end
  
  def test_should_return_image_tag_chosen_from_array
    assert_match %r{<img alt="Myimg" src="http://asset3.domain.com/images/myimg.jpg(\?\d*)?" />},
      image_tag('myimg.jpg')
  end
  
  def test_should_return_path_to_javascript
    assert_match %r{http://asset1.domain.com/javascripts/application.js(\?\d*)?},
      javascript_path('application')
  end
  
  def test_should_return_path_to_stylesheet
    assert_equal %r{http://asset1.domain.com/stylesheets/main.css(\?\d*)?},
      stylesheet_path('main')
  end
  
  protected
  
    def single_host!
      ActionController::Base.asset_host = 'http://assets.domain.com'
      ActionController::Base.asset_hosts = []
    end
    
    def multiple_hosts!
      ActionController::Base.asset_host = ''
      ActionController::Base.asset_hosts = %w( http://asset1.domain.com http://asset2.domain.com http://asset3.domain.com )
    end
end
