require File.dirname(__FILE__) + '/../test_helper'
require 'play_button_controller'
require 'yaml'

# Re-raise errors caught by the controller.
class PlayButtonController; def rescue_action(e) raise e end; end

class PlayButtonControllerTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
#    @controller = PlayButtonController.new
#    @request    = ActionController::TestRequest.new
#    @response   = ActionController::TestResponse.new
    
    # Don't overwrite the actual weights file
#    @controller.instance_eval do
#      def weights_file
#        "#{RAILS_ROOT}/test/weights.yml"
#      end
#    end
#    setup_weights_file(@controller.weights_file)
  end
  
  def test_index
#    login_as :suttree
#    get :index
#    assert @weights = assigns["weights"]
#    assert :success
  end
  
  def test_update
#    login_as :suttree
#    opts = { :mines => "1.2", :crates => "2.3", :portals => "4.5", :missions => "6.7" }
#    @pre = YAML.load_file(@controller.weights_file)
#    put :update, :weights => opts
#    @yaml = YAML.load_file(@controller.weights_file)
#    assert @pre['weights']['mines']    != @yaml['weights']['mines']
#    assert_equal @yaml['weights']['mines'], opts[:mines].to_f
#    assert @pre['weights']['missions'] != @yaml['weights']['missions']
#    assert_equal @yaml['weights']['missions'], opts[:missions].to_f
#    assert @pre['weights']['crates']   != @yaml['weights']['crates']
#    assert_equal @yaml['weights']['crates'], opts[:crates].to_f
#    assert @pre['weights']['portals']  != @yaml['weights']['portals']
#    assert_equal @yaml['weights']['portals'], opts[:portals].to_f
#    assert_redirected_to(:action => 'index')
  end
  
  protected
  def setup_weights_file(weights_file)
    #File.open(weights_file, 'r+') do |f|   # open file for update
    #  f.pos = 0                        # back to start
    #  f.print "weights:\n"
    #  { :mines => "20.2", :crates => "10.2", :portals => "32.3", :missions => "30" }.each {|key, value| f.print "  #{key}: #{value.to_f}\n"}
    #  f.truncate(f.pos)                # truncate to new length
    #end
  end
end
