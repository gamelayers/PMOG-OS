class Recommendation
  include Recommendations

  def domains
    @domains
  end

  def set_domains_for(users)
    @domains = {}
    users.each do |u|
      @domains[u.login] = u.daily_domains.hits :last_week
    end
    @domains
  end

  def users_for(login)
    self.topMatches(@domains, login)
  end

  def locations_for(login)
    self.getRecommendations(@domains, login)
  end
end
