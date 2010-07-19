class SecretQuestion < ActiveRecord::Base
  has_many :user_secrets
end
