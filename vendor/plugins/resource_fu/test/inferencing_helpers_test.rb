require File.join(File.dirname(__FILE__), 'test_helper')
require File.join(File.dirname(__FILE__), 'fixtures', 'inferencing_test_helpers_controller')
require 'test/unit'

class InferencingHelpersBaseTest < Test::Unit::TestCase
  include ActionView::Helpers::UrlHelper

  def setup
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller = InferencingHelpersController.new
  end

  def test_truth; assert true; end

  protected
  def with_nested_resource_expectation
    with_routing do |set|
      set.draw do |map|
        map.resources :widgets do |widget|
          widget.resources :flanges do |flange|
            flange.resources :grommets
          end
        end
        map.inferencing_helpers 'inferencing_helpers/:action', :controller => 'inferencing_helpers'
      end
      yield
      assert_equal expected_result, @response.body unless expected_result.nil?
    end
  end
end

class InferencingHelpersFlangeTest < InferencingHelpersBaseTest
  def test_specified_positional_path
    with_nested_resource_expectation { get :show_specified_positional_path }
  end

  def test_inferred_positional_path
    with_nested_resource_expectation { get :show_inferred_positional_path }
  end

  def test_instance_id_inference
    with_nested_resource_expectation { get :show_instance_id_inference }
  end

  def test_inference_precedence
    with_nested_resource_expectation { get :show_inference_precedence }
  end

  protected 
  def expected_result
    '/widgets/a_widget/flanges/a_flange'
  end
end

class InferencingHelpersGrommetTest
  def test_deep_inferred_positional_path
    with_nested_resource_expectation { get :show_deep_inferred_positional_path }
  end

  def test_positionals_always_overrides_instance_variables
    with_nested_resource_expectation { get :show_positionals_always_overrides_instance_variables }
  end

  def test_options_always_overrides_instance_variables
    with_nested_resource_expectation { get :show_options_always_overrides_instance_variables }
  end

  def test_positionals_always_overrides_options
    with_nested_resource_expectation { get :show_positionals_always_overrides_options }
  end

  protected
  def expected_result
    '/widgets/a_widget/flanges/a_flange/grommets/a_grommet'
  end
end

class InferencingHelpersExtraTest < InferencingHelpersBaseTest
  def test_collection_helpers_need_no_arguments
    with_nested_resource_expectation do
      get :show_collection_helpers_need_no_arguments
    end
    assert_equal '/widgets/a_widget/flanges/a_flange/grommets', @response.body
  end

  def test_explosion_because_terminating_member_is_never_inferred
    with_nested_resource_expectation do
      assert_raises ActionController::RoutingError do
        get :show_explosion_because_terminating_member_is_never_inferred
      end
    end
  end

  def test_explosion_on_too_many_positionals
    with_nested_resource_expectation do
      assert_raises ArgumentError do
        get :show_explosion_on_too_many_positionals
      end
    end
  end
  
  protected
  def expected_result
    nil # no automatic assertion please
  end
end