module Yahoo
  AuthHost = 'https://api.login.yahoo.com'
  Actions = {
    :authorize => '/WSLogin/V1/wslogin?',
    :get_credentials => '/WSLogin/V1/wspwtoken_login?'
  }
end