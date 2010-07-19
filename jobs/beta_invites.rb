sender = User.caches( :find_by_email, :with => 'self@pmog.com' )

user = User.find_by_email ARGV[0]
beta_user = BetaUser.find_by_email ARGV[0]

if user.nil?
  beta_user.email_beta_key(sender) unless beta_user.nil?
else
  beta_user.emailed = 1
end

beta_user.save(false)
  