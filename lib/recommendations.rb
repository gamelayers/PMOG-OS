# ----------------------------------------------------------------------
# 
# Ruby adaptations of the Python code found in Toby Segaran's
# Programming Collective Intelligence book.
# 
# steven.romej @ gmail (4 may 08)
# ----------------------------------------------------------------------

# From http://romej.com/downloads/collective/recommendations.rb
# See also http://216.239.59.104/search?q=cache:TiDszxYYPHoJ:loucal.net/index.php%3Fblog%3D2%26cat%3D14+ruby+sim_distance&hl=en&ct=clnk&cd=4&gl=uk&client=firefox-a

# recommendations.topMatches(domains, 'suttree') # returns recommended users
# recommendations.getRecommendations(domains, 'suttree') # returns recommended locations

module Recommendations
  # -------------------------------------------------
  # Euclidean distance 
  # -------------------------------------------------

  # Returns a distance-based similarity score for person1 and person2
  def sim_distance( prefs , person1 , person2 )
    # Get the list of shared_items
    si = {}
    for item in prefs[person1].keys
      if prefs[person2].include? item
        si[item] = 1
      end
    end

    # if they have no ratings in common, return 0
    return 0 if si.length == 0

    squares = []
    for item in prefs[person1].keys
      if prefs[person2].include? item
        squares << (prefs[person1][item] - prefs[person2][item]) ** 2
      end
    end

    sum_of_squares = squares.inject { |sum,value| sum += value }
    return 1/(1 + sum_of_squares.to_f)
  end

  # -------------------------------------------------
  # Pearson score
  # -------------------------------------------------

  # Returns the Pearson correlation coefficient for p1 and p2
  def sim_pearson( prefs, p1, p2)
    # Get the list of mutually rated items
    si = {}
    for item in prefs[p1].keys
      si[item] = 1 if prefs[p2].include? item
    end

    # Find the number of elements
    n = si.length
    # If there are no ratings in common, return 0
    return 0 if n == 0

    # Add up all the preferences
    sum1 = si.keys.inject(0) { |sum,value| sum += prefs[p1][value] }
    sum2 = si.keys.inject(0) { |sum,value| sum += prefs[p2][value] }

    # Sum up the squares
    sum1Sq = si.keys.inject(0) { |sum,value| sum += prefs[p1][value] ** 2 }
    sum2Sq = si.keys.inject(0) { |sum,value| sum += prefs[p2][value] ** 2 }

    # Sum up the products
    pSum = si.keys.inject(0) { |sum,value| sum += (prefs[p1][value] * prefs[p2][value])}

    # Calculate the Pearson score
    num = pSum - (sum1*sum2/n)
    den = Math.sqrt((sum1Sq - (sum1 ** 2)/n) * (sum2Sq - (sum2 ** 2)/n))

    return 0 if den == 0
    r = num / den
  end

  # Ranking the critics
  # TODO lacks the score-function-as-parameter aspect of original
  def topMatches( prefs, person, n=5, scorefunc = :sim_pearson )
    scores = []
    for other in prefs.keys
      if scorefunc == :sim_pearson
        scores << [ sim_pearson(prefs,person,other), other] if other != person
      else
        scores << [ sim_distance(prefs,person,other), other] if other != person
      end
    end
    return scores.sort.reverse.slice(0,n)
  end

  # Gets recommendations for a person by using a weighted average
  # of every other user's rankings
  # TODO just uses sim_pearson and not a function as parameter
  def getRecommendations(prefs, person, scorefunc = :sim_pearson )
    totals = {}
    simSums = {}
    for other in prefs.keys
      # don't compare me to myself
      next if other == person

      if scorefunc == :sim_pearson
        sim = sim_pearson( prefs, person, other)
      else
        sim = sim_distance( prefs, person, other)
      end

      # ignore scores of zero or lower
      next if sim <= 0

      for item in prefs[other].keys
        # only score movies I haven't seen yet
        if !prefs[person].include? item or prefs[person][item] == 0
          # similarity * score
          totals.default = 0
          totals[item] += prefs[other][item] * sim
          # sum of similarities
          simSums.default = 0
          simSums[item] += sim
        end
      end
    end

    # Create a normalized list
    rankings = []
    totals.each do |item,total|
      rankings << [total/simSums[item], item]
    end

    # Return the sorted list
    return rankings.sort.reverse
  end


  def transformPrefs( prefs )
    result = {}
    for person in prefs.keys
      for item in prefs[person].keys
        result[item] = {} if result[item] == nil
        # Flip item and person
        result[item][person] = prefs[person][item]
      end
    end
    return result
  end

  def calculateSimilarItems( prefs, n = 10 )
    # Create a dictionary of items showing which other items they are most similar to
    result = {}

    # Invert the preference matrix to be item-centric
    itemPrefs = transformPrefs(prefs)

    c = 0
    for item in itemPrefs.keys
      # Status updates for large datasets
      c += 1
      puts "#{c}/#{itemPrefs.length}" if c % 100 == 0
      # Find the most similar items to this one
      scores = topMatches(itemPrefs, item, n, :sim_distance)
      result[item] = scores
    end
    return result
  end


  def getRecommendedItems( prefs, itemMatch, user)
    userRatings = prefs[user]
    scores = {}
    totalSim = {}

    # Loop over items rated by this user
    userRatings.each do |item,rating|
      itemMatch[item].each do |similarity,item2|
        # Ignore if this user has already rated this item
        next if userRatings.include? item2

        # Weighted sum of rating times similarity
        scores[item2] = 0 if scores[item2] == nil
        scores[item2] += similarity * rating

        # Sum of all the similarities
        totalSim[item2] = 0 if totalSim[item2] == nil
        totalSim[item2] += similarity
      end
    end

    # Divide each total score by total weighting to get an average
    rankings = []
    scores.each do |item,score|
      rankings << [score/totalSim[item], item]
    end

    return rankings.sort.reverse
  end


  def loadMovieLens( path = "ml-data" )
    movies = {}
    File.open(path + "/u.item") do |file|
      while !file.eof?
        (id,title) = file.readline.split("|")[0,2]
        movies[id] = title
      end
    end

    prefs = {}
    File.open(path + "/u.data") do |file|
      while !file.eof?
        (user,movieid,rating,ts) = file.readline.split("\t")
        prefs[user] = {} if prefs[user] == nil
        prefs[user][movies[movieid]] = rating.to_f
      end
    end 
    return prefs
  end
end


# Just a test, kept for posterity
#class App
#
#  def run
#    # A dictionary of movie critics and their ratings of a small
#    # set of movies
#    critics = {'Lisa Rose'=> {'Lady in the Water'=> 2.5, 'Snakes on a Plane'=> 3.5,
# 'Just My Luck'=> 3.0, 'Superman Returns'=> 3.5, 'You, Me and Dupree'=> 2.5, 
# 'The Night Listener'=> 3.0},
# 'Gene Seymour'=> {'Lady in the Water'=> 3.0, 'Snakes on a Plane'=> 3.5, 
# 'Just My Luck'=> 1.5, 'Superman Returns'=> 5.0, 'The Night Listener'=> 3.0, 
# 'You, Me and Dupree'=> 3.5}, 
# 'Michael Phillips'=> {'Lady in the Water'=> 2.5, 'Snakes on a Plane'=> 3.0,
# 'Superman Returns'=> 3.5, 'The Night Listener'=> 4.0},
# 'Claudia Puig'=> {'Snakes on a Plane'=> 3.5, 'Just My Luck'=> 3.0,
# 'The Night Listener'=> 4.5, 'Superman Returns'=> 4.0, 
# 'You, Me and Dupree'=> 2.5},
# 'Mick LaSalle'=> {'Lady in the Water'=> 3.0, 'Snakes on a Plane'=> 4.0, 
# 'Just My Luck'=> 2.0, 'Superman Returns'=> 3.0, 'The Night Listener'=> 3.0,
# 'You, Me and Dupree'=> 2.0}, 
# 'Jack Matthews'=> {'Lady in the Water'=> 3.0, 'Snakes on a Plane'=> 4.0,
# 'The Night Listener'=> 3.0, 'Superman Returns'=> 5.0, 'You, Me and Dupree'=> 3.5},
# 'Toby'=> {'Snakes on a Plane'=>4.5,'You, Me and Dupree'=>1.0,'Superman Returns'=>4.0}
#    }
#
#
#    recommendations = Recommendations.new
#
#    # Test the Euclidean score code 
#    puts "The Euclidean distance score is #{recommendations.sim_distance( critics , "Lisa Rose", "Gene Seymour")}"
#    # Test the Pearson score
#    puts "The Pearson score is #{recommendations.sim_pearson( critics , "Lisa Rose" , "Gene Seymour" )}"
#    # Test the topMatches
#    puts recommendations.topMatches(critics,"Toby", 3)
#    # Try getting recommendations
#    puts recommendations.getRecommendations(critics,"Toby")
#    # Transform the preferences, get recommendation
#    movies = recommendations.transformPrefs( critics )
#    puts recommendations.topMatches( movies , "Superman Returns")
#
#    itemsim = recommendations.calculateSimilarItems(critics)
#    puts itemsim
#    puts recommendations.getRecommendedItems(critics, itemsim, "Toby")
#  end
#end
#
#app = App.new
#app.run
