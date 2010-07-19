class PurchaseController < ApplicationController
  def index
    @user = current_user
    @user_id = @user.id.gsub("-", "")
    # iframe displayed here
    @processor = Processor.find_by_name(Processor::get_name(Gambit::GAMBIT))
  end
end
