module NpcAssetsHelper
  def attachable_name
    # we know that @attachable is an NPC
    @attachable.name
  end
end