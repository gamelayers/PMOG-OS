class InventoryController < ApplicationController

	# GET /users/login/inventory
	def index
	  # return
    @inventory = User.find_by_login(params[:user_id]).inventory.to_hash

	  respond_to do |format|
	    format.html # index.rhtml
	    format.js   { render :json => OpenStruct.new(@inventory).to_js, :layout => false }
	    format.json { render :json => @inventory.to_json, :layout => false } # FIXME I AM NOT WRAPPED PROPERLY
	  end
	end
	
  # PUT /users/login/inventory
  def update
    return

    @inventory = Inventory.find(params[:id])

    respond_to do |format|
      if @inventory.update_attributes(params[:inventory])
        flash[:notice] = 'Inventory was successfully updated.'
        format.html { redirect_to inventory_url(@inventory) }
  	    format.js   { render :json => @inventory.to_js }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @inventory.errors.to_xml }
      end
    end
  end
end
