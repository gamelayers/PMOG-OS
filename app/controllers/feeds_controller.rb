# Feeds are NPC brainz
# The bird bot/npc stuff in here is ripe for refactoring
class FeedsController < ApplicationController
  before_filter :login_required

  layout 'application', :except => [ :new, :edit ]

  def new
    @feed = Feed.new
  end

  def create
    if params[:feed][:npc_id]
      @feed, @npc = create_npc_feed(params)
    elsif params[:feed][:bird_bot_id]
      @feed, @bird_bot = create_bird_bot_feed(params)
    end

    respond_to do |format|
      if @feed and @feed.valid?
        flash[:notice] = 'Brainz created'
        if params[:feed][:npc_id]
          format.html { redirect_to npc_path(@npc) }
          format.xml  { head :created, :location => npc_url(@npc) }
        elsif params[:feed][:bird_bot_id]
          format.html { redirect_to bird_bot_path(@bird_bot) }
          format.xml  { head :created, :location => bird_bot_url(@bird_bot) }
        end
      else
        format.html { redirect_to :action => 'new' }
        format.xml  { render :xml => @feed.errors.to_xml }
      end
    end
  end

  def edit
    @feed = Feed.find(params[:id])
  end

  def update
    if params[:feed][:npc_id]
      @feed, @npc = update_npc_feed(params)
    elsif params[:feed][:bird_bot_id]
      @feed, @bird_bot = update_bird_bot_feed(params)
    end

    flash[:notice] = 'Feed updated'
    if params[:feed][:npc_id]
      redirect_to npc_path(@npc)
    elsif params[:feed][:bird_bot_id]
      redirect_to bird_bot_path(@bird_bot)
    end
  end

  def destroy
    # Keep the feed, only delete this reference to it
    if params[:npc_id]
      @noc = delete_npc_feed(params)
    elsif params[:bird_bot_id]
      @bird_bot = delete_bird_bot_feed(params)
    end

    flash[:notice] = 'Feed deleted'
    if params[:npc_id]
      redirect_to npc_path(@npc)
    elsif params[:bird_bot_id]
      redirect_to bird_bot_path(@bird_bot)
    end
  end
  
  private
  # TODO - Move these to create fat models
  def create_npc_feed(options)
    @npc = Npc.find_by_url_name(options[:feed][:npc_id])
    return false if @npc.nil?
    
    # If feed exists, don't duplicate it
    url = Url.normalise(options[:feed][:url])
    if @feed = Feed.find_by_url(url)
      @npc.feeds << @feed unless @npc.feeds.include? @feed
    else
      @feed = @npc.feeds.create(:url => url)
    end
    [@feed, @npc]
  end
  
  def create_bird_bot_feed(options)
    @bird_bot = BirdBot.find_by_url_name(options[:bird_bot_id])
    return false if @bird_bot.nil?

    # If feed exists, don't duplicate it
    url = Url.normalise(options[:feed][:url])
    if @feed = Feed.find_by_url(url)
      @bird_bot.feed = @feed
      @bird_bot.save
    else
      @feed = @bird_bot.feed = Feed.create(:url => url)
      @bird_bot.feed = @feed
      @bird_bot.save
    end
    [@feed, @bird_bot]
  end
  
  def update_npc_feed(options)
    @npc = Npc.find_by_url_name(options[:npc_id])
    return false if @npc.nil?

    # Delete the existing feed
    @feed = Feed.find(options[:feed][:feed_id])
    @npc.feeds.delete(@feed)

    # Add the updated feed. If it exists, don't duplicate it
    url = Url.normalise(options[:feed][:url])
    if @feed = Feed.find_by_url(url)
      @npc.feeds << @feed unless @npc.feeds.include? @feed
    else
      @feed = @npc.feeds.create(:url => url)
    end
    [@feed, @npc]
  end
  
  def update_bird_bot_feed(options)
    @bird_bot = BirdBot.find_by_url_name(options[:bird_bot_id])
    return false if @bird_bot.nil?

    url = Url.normalise(options[:feed][:url])
    if @feed = Feed.find_by_url(url)
      @bird_bot.feed = @feed
      @bird_bot.save
    else
      @feed = @bird_bot.feed.create(:url => url)
      @bird_bot.feed = @feed
      @bird_bot.save
    end
    [@feed, @bird_bot]
  end
  
  def delete_npc_feed(options)
    @npc = Npc.find_by_url_name(options[:npc_id])
    @feed = Feed.find(options[:id])
    @npc.feeds.delete(@feed)
    @npc
  end
  
  def delete_bird_bot_feed(options)
    @bird_bot = BirdBot.find_by_url_name(options[:bird_bot_id])
    @bird_bot.feed = nil
    @bird_bot.save
    @bird_bot
  end
end