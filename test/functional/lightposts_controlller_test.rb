require File.dirname(__FILE__) + '/../test_helper'
require 'lightposts_controller'

# Re-raise errors caught by the controller.
class LightpostsController; def rescue_action(e) raise e end; end
  
class LightpostsControllerTest < ActionController::TestCase
  fixtures :users, :tags, :taggings, :levels, :inventories
  
  def setup
    super

    @suttree = users(:suttree)
    @suttree.inventory.set :lightposts, 5 
    @location  = Location.create(:url => 'http://www.google.uk')
#    assert @lightpost = @user.lightposts.create(:location_id => @location.id)
    login_as :suttree
  end
    
  def test_should_only_allow_one_lightpost_per_url_per_user
    post :create, :format => "json", :location_id => @location.id, :lightpost => { :description => 'Awesome site!', :tags => "" } 
    
    assert l = assigns(:lightpost)
    assert_equal l.location_id, @location.id
    assert_equal l.description, 'Awesome site!'
    
    # Successfuly laid light post
    assert @response.body =~ /Your lightpost is good to glow!/
    assert_equal @response.headers["Status"], "201 Created"
    
    # Should fail the second time
    post :create, :format => "json", :location_id => @location.id
    assert_response 422 
  end
  
  def test_should_allow_user_to_edit_lightpost
    assert @lightpost = @suttree.lightposts.create(:location_id => @location.id)

    get :edit, :id => @lightpost.id
    assert_response :success
    assert l = assigns(:lightpost)
    assert @suttree.lightposts.include?(l)
  end
  
  def test_should_allow_user_to_delete_lightpost
    assert @lightpost = @suttree.lightposts.create(:location_id => @location.id)
    
    delete :destroy, :id => @lightpost.id
    assert_redirected_to user_lightposts_path(@suttree)
    assert l = assigns(:lightpost)
    assert !@suttree.lightposts(true).include?(@lightpost)
  end
  
  def test_should_not_allow_user_to_delete_others_lightpost
    assert @suttrees_lightpost = @suttree.lightposts.create(:location_id => @location.id)
    
    login_as :alex
    delete :destroy, :id => @suttrees_lightpost.id

    assert_redirected_to('/')
    assert flash[:error] =~ /Could not find lightpost/i

    assert @suttree.lightposts.include?(@suttrees_lightpost)
  end
  
  def test_should_allow_user_to_update_lightpost
    assert @lightpost = @suttree.lightposts.create(:location_id => @location.id)
    description = "OMG PMOG"
    put :update, :id => @lightpost.id, :lightpost => { :description => description }
    assert_redirected_to user_lightposts_path(@suttree)
    assert flash[:notice] =~ /Changes Saved/
    assert l = @suttree.lightposts.find(assigns(:lightpost).id)
    assert_equal l.description, description
  end
  
  def test_should_not_allow_user_to_update_others_lightpost
    assert @suttrees_lightpost = @suttree.lightposts.create(:location_id => @location.id)
    description = "OMG PMOG"

    login_as :alex
    
    put :update, :id => @suttrees_lightpost.id, :lightpost => { :description => description }

    assert_redirected_to('/')
    assert flash[:error] =~ /Could not find lightpost/i
    assert @suttrees_lightpost.reload.description != description
  end
  
  def test_update_with_bad_params
    assert @lightpost = @suttree.lightposts.create(:location_id => @location.id)
    # Missing lightpost hash
    put :update, :id => @lightpost.id
    assert_redirected_to edit_user_lightpost_path(@suttree, @lightpost)
    assert flash[:error] =~ /you are missing a required parameter/i
    
    # Missing the location key within the lightpost hash
    put :update, :id => @lightpost.id, :lightpost => {}
    assert_redirected_to edit_user_lightpost_path(@suttree, @lightpost)
    assert flash[:error] =~ /you are missing a required parameter/i
  end
  
  def test_create_with_tags
    assert_difference Lightpost, :count do
      post :create, :format => "json", :location_id => @location.id, :lightpost => { :description => 'Caffeine ++', :tag_list => "new tag" }
    end

    assert l = assigns(:lightpost)
    assert_equal l.location_id, @location.id
    assert_equal 1, l.tags.count
    assert_equal "new tag", l.tags.first.name
    
    @location  = Location.create(:url => 'http://www.cnn.com')
    
    post :create, :format => "json", :location_id => @location.id, :lightpost => { :description => 'News', :tag_list => "news, cnn, stories, reading" }
    
    assert l = assigns(:lightpost)
    assert_equal l.location_id, @location.id
    assert_equal 4, l.tags.count
    
    tags = l.tag_counts(:order => 'name')
    assert_equal "cnn", tags[0].name
    assert_equal "news", tags[1].name
    assert_equal "reading", tags[2].name
    assert_equal "stories", tags[3].name 
    
    # Test older style "tags" params used by older extensions
    @location  = Location.create(:url => 'http://www.cnn.co.uk')
    
    post :create, :format => "json", :location_id => @location.id, :lightpost => { :description => 'News', :tags => "news, cnn, stories, reading" }
    
    assert l = assigns(:lightpost)
    assert_equal l.location_id, @location.id
    assert_equal 4, l.tags.count
    
    tags = l.tag_counts(:order => 'name')
    assert_equal "cnn", tags[0].name
    assert_equal "news", tags[1].name
    assert_equal "reading", tags[2].name
    assert_equal "stories", tags[3].name 
    
  end
  
  def test_create_with_unusual_tags
    # Marc is fixing this issue but right now multi-word tags do not work.
  end
    
  
  def test_sort
  #  create_lightpost_and_login
  #  @location  = Location.create(:url => 'http://www.google.se')
  #  @lightpost_a = @user.lightposts.create(:location_id => @location.id, :description => 'ABCDE')
  #  assert @lightpost_a.valid?
    
  #  @location  = Location.create(:url => 'http://www.google.cn')
  #  @lightpost_b = @user.lightposts.create(:location_id => @location.id, :description => 'EDCBA')
  #  assert @lightpost_b.valid?
    
  #  get :sort, :column => 'description', :order => 'asc'
    
   # assert_response :success
  end
  
  
end
