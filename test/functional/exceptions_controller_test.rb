require File.dirname(__FILE__) + '/../test_helper'
require 'exceptions_controller'

# Re-raise errors caught by the controller.
class ExceptionsController; def rescue_action(e) raise e end; end
  
class ExceptionsControllerTest < ActionController::TestCase
  fixtures :users
  
  def setup
    super
    ActionMailer::Base.delivery_method = :test  
    ActionMailer::Base.perform_deliveries = true
    
    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end
  
  def test_create_bug_report
    @user = User.find_by_login('suttree')
    @user_email = 'foo@bar.com'
    @user_description = "You have some bugs!"
    @user_dump = "authenticated%3Dtrue%26primary_association%3DShoat%26secondary_association%3DShoat%26tertiary_association%3DShoat%26login%3Dheavysixer%26level%3D2%26next_level%3D3%26levelup_requirements%3Dyou%2520need%25201410%2520datapoints%252C%2520and%2520probably%2520some%2520more%2520tool%2520use%2520to%2520level%2520up%2521%26level_percentage%3D53%26datapoints%3D192%26mines%3D48%26lightposts%3D16%26portals%3D29%26crates%3D91%26classpoints%3D80%26st_nicks%3D19%26armor%3D1246%26armored%3Dtrue%26id%26auth_token%3D0004de42d974de0be608aec913a753d5b6193749%26authenticity_token%3Dfa267ddbf6f9dac352fb09432a9140ac94e6875a%26type%26avatar_mini%3D/images/shared/elements/user_default_mini.jpg%26class%3DPmogUser%26user_id%3D4c2fa886-f5db-11dc-86e6-0016cb88feaa%26sound_preference%3Dtrue%26skin%3Dclassic%26panel_id%3Dpanel1211219695826%26url%5Bhref%5D%3Dhttp%253A//www.google.com/%26url%5Bhost%5D%3Dwww.google.com%26loaded%3Dtrue%26class%3DPage%26loaded%26page%5Bclass%5D%3DPage%26"
    login_as :suttree
    
    post :bug_report, { :format => "json", :id => @user.login, :version => '0.412', :exception => { :dump => @user_dump, :email => @user_email, :description => @user_description } }
    
    # Test the overlay
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert flash[:notice] =~ /Thank you for your bug report./

    assert json_response['messages'].first['body'] =~ /#{flash[:notice]}/
    assert_response 201
    
    # Test the generated email
    assert @emails.size == 1
    assert @emails.first.to.include?('gamelayers@gmail.com')
    assert @emails.first.body =~ /#{@user_email}/
    assert @emails.first.body =~ /#{@user_description}/
    assert @emails.first.body =~ /#{@user_dump}/
  end
  
  def test_create_bug_report_bad_params
    @user = User.find_by_login('suttree')
    login_as :suttree
    
    post :bug_report, { :format => "json", :id => @user.login, :version => '0.412' }
    
    # Test the overlay
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert flash[:notice] =~ /Thank you for your bug report./
    assert json_response['messages'].first['body'] =~ /#{flash[:notice]}/
    assert_response 201
    
    # No emails should be sent without the required parameters.
    assert @emails.empty?
  end
end
  
