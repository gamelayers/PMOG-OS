class UserTagsController < ApplicationController
  def index
    @user = User.find(params[:user_id])
    @tags = @user.missions.tag_counts(:order => 'name')
  end

  def show
    @user = User.find(params[:user_id])
    @missions = @user.missions.find_tagged_with(params[:id])
  end
end
