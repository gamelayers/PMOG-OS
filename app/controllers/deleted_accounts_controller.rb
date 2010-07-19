class DeletedAccountsController < ApplicationController
  
  before_filter :protect
  
  # GET /deleted_accounts
  # GET /deleted_accounts.xml
  def index
  	@page_title = "Deleted Accounts Listing on "
    @deleted_accounts = DeletedAccount.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @deleted_accounts }
    end
  end

  # GET /deleted_accounts/1
  # GET /deleted_accounts/1.xml
  def show
    @deleted_account = DeletedAccount.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @deleted_account }
    end
  end

  # GET /deleted_accounts/new
  # GET /deleted_accounts/new.xml
  def new
    @deleted_account = DeletedAccount.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @deleted_account }
    end
  end

  # GET /deleted_accounts/1/edit
  def edit
    @deleted_account = DeletedAccount.find(params[:id])
  end

  # POST /deleted_accounts
  # POST /deleted_accounts.xml
  def create
    @deleted_account = DeletedAccount.new(params[:deleted_account])

    respond_to do |format|
      if @deleted_account.save
        flash[:notice] = 'DeletedAccount was successfully created.'
        format.html { redirect_to(@deleted_account) }
        format.xml  { render :xml => @deleted_account, :status => :created, :location => @deleted_account }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @deleted_account.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /deleted_accounts/1
  # PUT /deleted_accounts/1.xml
  def update
    @deleted_account = DeletedAccount.find(params[:id])

    respond_to do |format|
      if @deleted_account.update_attributes(params[:deleted_account])
        flash[:notice] = 'DeletedAccount was successfully updated.'
        format.html { redirect_to(@deleted_account) }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @deleted_account.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /deleted_accounts/1
  # DELETE /deleted_accounts/1.xml
  def destroy
    @deleted_account = DeletedAccount.find(params[:id])
    @deleted_account.destroy

    respond_to do |format|
      format.html { redirect_to(deleted_accounts_url) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def protect
    unless site_admin?
      flash[:notice] = "You can't access this unless you're an admin!"
      redirect_to "/"
      return false
    end
  end
  
end
