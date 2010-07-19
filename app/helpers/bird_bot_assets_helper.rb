module BirdBotAssetsHelper
  def attachable_name
    # we know that @attachable is a Bird Bot
    @attachable.name
  end
end