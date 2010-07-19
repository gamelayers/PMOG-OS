module PrivacyHelper
  
  #Builds the radio box for the supplied values.
  # option  - the name of the privacy option
  # value   - the value to build into the radio
  # user_id - needs no explaination.
  def get_privacy(option, value, user_id)
    @name = "preference[#{user_id}-#{option}]"
    @preference = Preference.find_by_name_and_user_id(option, user_id)
    if @preference.nil?
      user = User.find_by_id(user_id)
      user.preferences.set option, "Public"
      @preference = user.preferences.get option
    end
    if @preference.value == value
      checked = ' checked'
    end
    return "<input name=\"#{@name}\" type=\"radio\" value=\"#{value}\"#{checked}>"
  end
  
  #Builds the checkbox for the email preferences
  # option  - the name of the privacy option
  # user_id - needs no explaination.
  # input_id - the ID attribute to attach to the checkbox
  def get_preference_checkbox(option, user_id, input_id = "")
    @name = "preference[#{user_id}-#{option}]"
    @preference = Preference.find_by_name_and_user_id(option, user_id)
    if @preference.nil?
      user = User.find_by_id(user_id)
      user.preferences.set option, true
      @preference = user.preferences.get option
    end
    if @preference.value == "true"
      checked = 'checked=\"checked\"'
    end
    return "<input class='pref-input' type='checkbox' name=\"#{@name}\" id=\"#{input_id.gsub(' ', '_')}\" #{checked}>"
  end
  
end
