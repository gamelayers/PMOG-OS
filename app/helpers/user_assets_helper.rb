module UserAssetsHelper
  def attachable_name
    # we know that @attachable is a User
    @attachable.login
  end
end