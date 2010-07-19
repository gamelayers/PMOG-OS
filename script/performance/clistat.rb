#!/usr/bin/env ruby
 
# clistat
# Computer basic statistics from a run of curl benchmarks, it should probably be
# generalized to work from output from any cli app that gives numerical results
# one per line.
#
# From http://gist.github.com/12470
#
# Sample Usage and Output
# -----------------------------------------------------------------------------
#   $ while true; do curl --silent --head --cookie "www_pmog_session_id=1234567890" http://pmog.com | grep X-Runtime; done | script/performance/clistat.rb 
#   X-Runtime: 0.26761
#   X-Runtime: 0.13938
#   X-Runtime: 0.14778
#   X-Runtime: 0.27382
#   X-Runtime: 0.14642
#   X-Runtime: 0.14412
#   X-Runtime: 0.29516
#   X-Runtime: 0.26926
#   X-Runtime: 0.14535
#   ^C
#   
#   Statistics
#   ----------------
#   n:      8
#   sum:    1.561290
#   mean:   0.195161
#   min:    0.139380
#   max:    0.295160
#   stdev:  0.065666
#   ----------------
#
 
# from http://codesnippets.joyent.com/posts/show/1159
class Array
  def sum
    inject( nil ) { |sum,x| sum ? sum+x : x }
  end
 
  def mean
    sum=0
    self.each {|v| sum += v}
    sum/self.size.to_f
  end
 
  def variance
    m = self.mean
    sum = 0.0
    self.each {|v| sum += (v-m)**2 }
    sum/self.size
  end
 
  def stdev
    Math.sqrt(self.variance)
  end
 
  def count                                 # => Returns a hash of objects and their frequencies within array.
    k=Hash.new(0)
    self.each {|x| k[x]+=1 }
    k
  end
    
  def ^(other)                              # => Given two arrays a and b, a^b returns a new array of objects *not* found in the union of both.
    (self | other) - (self & other)
  end
 
  def freq(x)                               # => Returns the frequency of x within array.
    h = self.count
    h(x)
  end
 
  def maxcount                              # => Returns highest count of any object within array.
    h = self.count
    x = h.values.max
  end
 
  def mincount                              # => Returns lowest count of any object within array.
    h = self.count
    x = h.values.min
  end
 
  def outliers(x)                           # => Returns a new array of object(s) with x highest count(s) within array.
    h = self.count                                                              
    min = self.count.values.uniq.sort.reverse.first(x).min
    h.delete_if { |x,y| y < min }.keys.sort
  end
 
  def zscore(value)                         # => Standard deviations of value from mean of dataset.
    (value - mean) / stdev
  end
end
 
class Clistat
  attr_accessor :stats
  attr_accessor :n, :sum, :mean, :min, :max, :stdev
 
  def initialize
    @stats = []
  end
  
  def compute!
    @stats.shift            # remove the first element
    
    @stats.map! {|s| s.gsub('X-Runtime: ', '').to_f rescue 0.0 }
    
    @n = @stats.size
    @sum = @stats.sum
    @mean = @stats.mean
    @min = @stats.min
    @max = @stats.max
    @stdev = @stats.stdev
  end
  
  def output
    puts "\n\n"
    puts "Statistics"
    puts "-" * 16
  
    compute!
    
    puts "n:\t%d" % @n
    puts "sum:\t%f" % @sum
    puts "mean:\t%f" % @mean
    puts "min:\t%f" % @min
    puts "max:\t%f" % @max
    puts "stdev:\t%f" % @stdev
 
    puts "-" * 16
  end
end
 
clistat = Clistat.new
 
Signal.trap("INT") do
  puts clistat.output
end
 
while gets
  puts $_ if !$_.nil?
  clistat.stats << $_.chomp
end
