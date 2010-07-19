class GambitProcessor < ActiveRecord::Migration
  def self.up
    Processor.create(:name => 'gambit',             :campaign_key=> 'd70c9c8194f8ba3160e9b67b925a47e6', :secret_key => '32ce0b3aa4d9daf56b7a95661e7d9813')
    Processor.create(:name => 'gambit_development', :campaign_key=> '8f0fd9943cc3b076b053a97b637b0dda', :secret_key => '098a0f145cceabd06b9ddbe1385758f1')
    Processor.create(:name => 'gambit_staging',     :campaign_key =>'8647996d95010a4b5b5962cfafc1d519', :secret_key => 'bb82b562bd6982853b76bfd30abdcd6c')
  end 
      
  def self.down
    Processor.delete_all(:name => 'gambit')
    Processor.delete_all(:name => 'gambit_dev')
    Processor.delete_all(:name => 'gambit_staging')
  end 
end   
