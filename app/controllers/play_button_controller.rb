require 'yaml'
class PlayButtonController < ApplicationController
  before_filter :login_required
  ##before_filter :authenticate
  permit 'site_admin'

  def index
    @page_title = "Event Weighting for the Play Button from "
    @yaml = YAML.load_file(weights_file)
    @weights = OpenStruct.new(@yaml["weights"])
  end

  def update
    File.open(weights_file, 'r+') do |f|   # open file for update
        f.pos = 0                        # back to start
        f.print "weights:\n"
        params[:weights].each {|key, value| f.print "  #{key}: #{value.to_f}\n"}
        f.truncate(f.pos)                # truncate to new length
    end
    User.expire_cache('weights')
    flash[:notice] = "Weights updated"
    redirect_to :action => :index
  end

  protected
  def weights_file
    WEIGHTS_FILE
  end
end
