namespace :bleak_house do
  desc 'Analyze and chart all data'  
  task :analyze do    
    require 'bleak_house/analyze' 
    BleakHouse::Analyze.build_all("#{RAILS_ROOT}/log/bleak_house_#{RAILS_ENV}.yaml.log")
  end  
end
