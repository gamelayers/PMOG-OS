require File.dirname(__FILE__) + '/spec_helper'
require 'fast_sessions'

describe "CGI::Session::ActiveRecordStore::FastSessions Class" do
  it "should have connection attribute" do
    connection = mock("connection")
    CGI::Session::ActiveRecordStore::FastSessions.connection = connection
    CGI::Session::ActiveRecordStore::FastSessions.connection.should be(connection)
  end

  it "should have table_name attribute" do
    CGI::Session::ActiveRecordStore::FastSessions.table_name = "table_name"
    CGI::Session::ActiveRecordStore::FastSessions.table_name.should == "table_name"
  end

  it "should correctly marshal/unmarshal data" do
    data = [ "some", { :test => 'data', :structure => 1}, "to", :check, 'serializat', 10, "n" ]
    marshaled_data = CGI::Session::ActiveRecordStore::FastSessions.marshal(data)
    marshaled_data.should_not be(nil)
    CGI::Session::ActiveRecordStore::FastSessions.unmarshal(marshaled_data).should == data
  end
end

describe "FashSessions Class find_by_session_id() method" do
  before(:each) do
    @connection = mock("connection")
    @connection.stub!(:quote).and_return("something")
    CGI::Session::ActiveRecordStore::FastSessions.connection = @connection
    CGI::Session::ActiveRecordStore::FastSessions.fallback_to_old_table = false

    @data = { :test => "value" }
    @marshaled_data = CGI::Session::ActiveRecordStore::FastSessions.marshal(@data)
  end
  
  it "should return a CGI::Session::ActiveRecordStore::FastSessions object with saved data when called for existing session" do
    @connection.should_receive(:select_one).and_return({'data' => @marshaled_data})
    session = CGI::Session::ActiveRecordStore::FastSessions.find_by_session_id("test_id")
    session.class.should be(CGI::Session::ActiveRecordStore::FastSessions)
    session.data.should == @data
  end

  it "should return a CGI::Session::ActiveRecordStore::FastSessions object with empty hash when called for non-existing session" do
    @connection.should_receive(:select_one).and_return(nil)
    session = CGI::Session::ActiveRecordStore::FastSessions.find_by_session_id("test_id")
    session.class.should be(CGI::Session::ActiveRecordStore::FastSessions)
    session.data.should be_empty
  end

  it "should fallback to the old sessions table if session was not found in new one" do
    @connection.should_receive(:select_one).twice.and_return(nil, {'data' => @marshaled_data})
    CGI::Session::ActiveRecordStore::FastSessions.fallback_to_old_table = true

    session = CGI::Session::ActiveRecordStore::FastSessions.find_by_session_id("test_id")
    session.class.should be(CGI::Session::ActiveRecordStore::FastSessions)
    session.data.should == @data
  end
end

describe "FashSessions object save() method" do
  before(:each) do
    @data = { :test => "value" }
    @marshaled_data = CGI::Session::ActiveRecordStore::FastSessions.marshal(@data)

    @connection = mock("connection")
    @connection.stub!(:quote).and_return("something")
    @connection.should_receive(:select_one).and_return({'data' => @marshaled_data})
    CGI::Session::ActiveRecordStore::FastSessions.connection = @connection
    CGI::Session::ActiveRecordStore::FastSessions.fallback_to_old_table = false
    
    @session = CGI::Session::ActiveRecordStore::FastSessions.find_by_session_id("test_id")
  end
  
  it "should not save data if should_save_session? returns false" do
    @session.should_receive(:should_save_session?).and_return(false)
    @connection.should_not_receive(:update)
    @session.save
  end

  it "should save data if should_save_session? returns true" do
    @session.should_receive(:should_save_session?).and_return(false)
    @connection.should_not_receive(:update)
    @session.save
  end
  
  it "should not save data if it was not changed" do
    @connection.should_not_receive(:update)
    @session.save
  end

  it "should save data if it was changed" do
    @connection.should_receive(:update)
    @session.data[:ping] = "pong"
    @session.save
  end

  it "should not save data if it was changed, but user requested to skip saving" do
    @connection.should_not_receive(:update)
    @session.data[:ping] = "pong"
    @session.data[:skip_session_saving] = true
    @session.save
  end

  it "should delete :skip_session_saving and :force_session_saving from data hash" do
    @connection.should_receive(:update)
    @session.data[:skip_session_saving].should be_nil
    @session.data[:foce_session_saving].should be_nil
    
    @session.data[:skip_session_saving] = true
    @session.data[:force_session_saving] = true
    @session.save

    @session.data[:skip_session_saving].should be_nil
    @session.data[:foce_session_saving].should be_nil
  end

  it "should save data if it was changed and user requested to force saving" do
    @connection.should_receive(:update)
    @session.data[:ping] = "pong"
    @session.data[:force_session_saving] = true
    @session.save
  end

  it "should save data if it was not changed, but user requested to force saving" do
    @connection.should_receive(:update)
    @session.data[:force_session_saving] = true
    @session.save
  end

  it "should save data skip and force saving were requested (force has higher priority)" do
    @connection.should_receive(:update)
    @session.data[:skip_session_saving] = true
    @session.data[:force_session_saving] = true
    @session.save
  end
end

describe "FashSessions object save() method in special cases" do
  before(:each) do
    @data = { :test => "value" }
    @marshaled_data = CGI::Session::ActiveRecordStore::FastSessions.marshal(@data)

    @connection = mock("connection")
    @connection.stub!(:quote).and_return("something")
    CGI::Session::ActiveRecordStore::FastSessions.connection = @connection
    CGI::Session::ActiveRecordStore::FastSessions.fallback_to_old_table = false
  end

  it "should not save data if the only thing added to an empty session was a blank flash message" do
    @connection.should_receive(:select_one).and_return(nil)
    @session = CGI::Session::ActiveRecordStore::FastSessions.find_by_session_id("another_id")

    @connection.should_not_receive(:update)
    @session.data["flash"] = {}
    @session.save
  end
end
