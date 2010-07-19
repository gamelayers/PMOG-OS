class MarkovText
  def self.sample
    dir = File.dirname(__FILE__)
    `ruby #{dir}/markov_chains.rb`
  end
end