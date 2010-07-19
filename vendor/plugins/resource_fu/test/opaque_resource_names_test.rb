require File.join(File.dirname(__FILE__), 'test_helper')
require File.join(File.dirname(__FILE__), 'fixtures', 'opaque_resource_names_test_controller')
require 'test/unit'

class OpaqueResourceNamesTest < Test::Unit::TestCase
  include ActionView::Helpers::UrlHelper

  def setup
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller = OpaqueResourceNamesTestController.new
  end

  def test_singular_widget
    with_nested_singulars { get :show_widget_path }
    assert_equal '/buffalo', @response.body
  end

  def test_singular_flange
    with_nested_singulars { get :show_flange_path }
    assert_equal '/buffalo/buffalo', @response.body
  end

  def test_singular_grommet
    with_nested_singulars { get :show_grommet_path }
    assert_equal '/buffalo/buffalo/buffalo', @response.body
  end
  
  def test_show_widgets_path
    with_nested_collections { get :show_widgets_path }
    assert_equal '/buffalo', @response.body
  end
  
  def test_show_widgets_member_path
    with_nested_collections { get :show_widgets_member_path }
    assert_equal '/buffalo/a_widget', @response.body
  end
  
  def test_show_grommets_path
    with_nested_collections { get :show_grommets_path }
    assert_equal '/buffalo/a_widget/buffalo/a_flange/buffalo', @response.body
  end
  
  def test_show_grommets_member_path
    with_nested_collections { get :show_grommets_member_path }
    assert_equal '/buffalo/a_widget/buffalo/a_flange/buffalo/a_grommet', @response.body
  end

  protected
  def with_nested_singulars
    with_routing do |set|
      set.draw do |map|
        map.resource :widget, :opaque_name => 'buffalo' do |widget|
          widget.resource :flange, :opaque_name => 'buffalo' do |flange|
            flange.resource :grommet, :opaque_name => 'buffalo'
          end
        end
        map.opaque_names 'opqaque_resource_names_test/:action', :controller => 'opaque_resource_names_test'
      end
      yield
    end
  end

  def with_nested_collections
    with_routing do |set|
      set.draw do |map|
        map.resources :widgets, :opaque_name => 'buffalo' do |widget|
          widget.resources :flanges, :opaque_name => 'buffalo' do |flange|
            flange.resources :grommets, :opaque_name => 'buffalo'
          end
        end
        map.opaque_names 'opqaque_resource_names_test/:action', :controller => 'opaque_resource_names_test'
      end
      yield
    end
  end
end