class HudsController < ApplicationController
  before_filter :login_required

  def show
    @user = current_user
    @preferences = Hash.new
    prefs = {}
    Preference.preferences.each_pair{ | k, v | prefs[Preference.preferences[k][:text]] = Preference.preferences[k][:default] }
    
    # Assign any missing values to these preferenves.
    @user.preferences.ensure_defaults_for(prefs).map{ |x| @preferences[x.name] = x.value }
    
    @groups = [
     { :label => 'Content Settings', :settings => Preference.content_group } 
    ]
    # Convert preferences to an open struct to ensure that the rails forms can automatically retrive the right values.
    @preferences = OpenStruct.new(@preferences)
    respond_to do |format|
      format.ext #index.ext.erb
    end
  end  
end