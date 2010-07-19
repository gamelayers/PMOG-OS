class InsertPortalTransportationsIntoMiscActions < ActiveRecord::Migration
  def self.up
		@portal_transportation = MiscAction.find_by_url_name("portal_transportation")

		if(@portal_transportation.nil?)
      MiscAction.reset_column_information
      MiscAction.create( :name => "Portal Transportation",
        :url_name => "portal_transportation",
        :association_id => PmogClass.find_by_name('Seers').id,
        :classpoints => 1)
    end
  end

  def self.down
  end
end
