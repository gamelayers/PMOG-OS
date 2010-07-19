ActionController::RequestForgeryProtection.module_eval do
  alias :original_verify_authenticity_token :verify_authenticity_token

  def verify_authenticity_token(*args)
    # Skip the CSRF protection for remote logins from the extension. Note that the skip_before_filter
    # fails if you call it from the Sessions Controller, so we module_eval it here instead.
    # See http://tinyurl.com/35xpth
    if self.class.to_s == 'SessionsController' and action_name == 'create' and params['format'] == 'js'
      # Pretend to call this before_filter.
      true
    elsif self.class.to_s == 'SessionsController' and action_name == 'create' and params['format'] == 'json'
      # .json works to
      true
    elsif self.class.to_s == "UsersController" and action_name == 'create' and params['format'] == 'json'
      true
    else
      original_verify_authenticity_token(*args)
    end
  end
end