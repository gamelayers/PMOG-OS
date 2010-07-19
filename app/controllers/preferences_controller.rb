class PreferencesController < ApplicationController  
  # POST /users/login/preferences
  def create
    @preference = current_user.preferences.toggle( params[:preference][:name], params[:preference][:value] )
    @window_id = Time.now.to_i
    respond_to do |format|
      format.js {
        overlay = {}
        overlay[:preferences] = []
        # Just use the 'update' template here
        overlay[:preferences] << { :id => @window_id, :type => "Preference", :subject => "", :body => render_to_string( :partial => "preferences/update", :layout => false ) }
        overlay[:user] = current_user_data
        add_empty_page_objects_to(overlay)
        render :json => OpenStruct.new(overlay).send(:table).to_json
      }
    end
  end

  # PUT /users/login/preferences
  def update
    respond_to do |format|
      format.js {
        @window_id = Time.now.to_i
        @preference = current_user.preferences.toggle( params[:preference][:name], params[:preference][:value] )
        overlay = {}
        overlay[:preferences] = []
        overlay[:preferences] << { :id => @window_id, :type => "Preference", :subject => "", :body => render_to_string( :partial => "preferences/update", :layout => false ) }
        overlay[:user] = current_user_data
        add_empty_page_objects_to(overlay)
        render :json => OpenStruct.new(overlay).send(:table).to_json
      }
      format.ext {
        if params[:format] && params[:format].to_s == 'ext'
          begin
            raise ArgumentError unless params[:preferences]
            if current_user.preferences.update_all(params[:preferences])
              flash[:notice] = "Your preferences have been saved."
              redirect_to hud_path(:format => 'ext')
            else
              raise ArgumentError # Might want to be more specific later
            end
          rescue ArgumentError
            flash[:error] = "You are missing required fields in your form submission."
            redirect_to hud_path(:format => 'ext')
          end
        else
          redirect_back_or_default('/')
        end
      }
    end
  end
end
