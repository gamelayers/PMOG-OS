class UserSecretsController < ApplicationController
  before_filter :find_userSecret, :only => [:show, :edit, :update, :destroy]
  before_filter :deny_all, :only => [:show, :edit, :destroy, :index, :new]
  before_filter :check_logged_in, :only => [:create, :update]
  # GET /userSecrets
  # GET /userSecrets.xml
  def index
    @userSecrets = UserSecret.all

    respond_to do |wants|
      wants.html # index.html.erb
      wants.xml  { render :xml => @userSecrets }
    end
  end

  # GET /userSecrets/1
  # GET /userSecrets/1.xml
  def show
    respond_to do |wants|
      wants.html # show.html.erb
      wants.xml  { render :xml => @userSecret }
    end
  end

  # GET /userSecrets/new
  # GET /userSecrets/new.xml
  def new
    @userSecret = UserSecret.new

    respond_to do |wants|
      wants.html # new.html.erb
      wants.xml  { render :xml => @userSecret }
    end
  end

  # GET /userSecrets/1/edit
  def edit
  end

  # POST /userSecrets
  # POST /userSecrets.xml
  def create
    #@userSecret = UserSecret.new(params[:userSecret])
    @userSecret = current_user.build_user_secret(params[:user_secret])

    respond_to do |wants|
      if @userSecret.save
        flash[:notice] = 'UserSecret was successfully created.'
        wants.html { redirect_to(edit_user_path(current_user)) }
      else
      end
    end
  end

  # PUT /userSecrets/1
  # PUT /userSecrets/1.xml
  def update
    respond_to do |wants|
      if @userSecret.update_attributes(params[:user_secret])
        flash[:notice] = 'UserSecret was successfully updated.'
        wants.html { redirect_to(edit_user_path(current_user)) }
      else
      end
    end
  end

  # DELETE /userSecrets/1
  # DELETE /userSecrets/1.xml
  def destroy
    @userSecret.destroy

    respond_to do |wants|
      wants.html { redirect_to(userSecrets_url) }
      wants.xml  { head :ok }
    end
  end

  private
    def find_userSecret
      @userSecret = UserSecret.find(params[:id])
    end

    def deny_all
      redirect_to "/"
    end

    def check_logged_in
      unless logged_in?
        deny_all
      end
    end
end

