#!/usr/local/bin/ruby -w

# Copyright (c) 2007 Topfunky Corporation
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "rubygems"
require "production_log/analyzer"
require "gruff"
require 'yaml'

##
# Parses a logfile of results from httperf and generates a graph.
#
# USAGE:
#
#   parse_httperf_log.rb sample-log.txt
#
# AUTHOR: Geoffrey Grosenbach http://peepcode.com
#

class ParseHttperfLog

  def self.run
    new(ARGV.first || usage()).run
  end

  def usage
    puts <<-USAGE
    USAGE:
    #{$0} logfile_name

    The logfile should have the "Reply rate" line from several httperf runs:

    Reply rate [replies/s]: min 548.8 avg 602.5 max 705.4 stddev 89.1 (3 samples)
    USAGE
  end

  def initialize(logfile_name)
    @logfile_name = logfile_name
    @stats = {
      :min => [],
      :avg =>[],
      :max => [],
      :stddev => []
    }
  end

  def run
    parse_log
    generate_graph
    print_stats
  end

  def parse_log
    File.open(@logfile_name).readlines.each do |line|
      next if line =~ /^#/
      if line =~ /Reply rate \[replies\/s\]: min ([0-9.]+) avg ([0-9.]+) max ([0-9.]+) stddev ([0-9.]+)/
        @stats[:min] << $1.to_f
        @stats[:avg] << $2.to_f
        @stats[:max] << $3.to_f
        @stats[:stddev] << $4.to_f
      end
    end
  end

  def generate_graph
    g = Gruff::Line.new
    g.title = "httperf Stats"

    hash = Hash.new
    pages = [ 'index', 'missions', 'npcs', 'bird_bots', 'beta_signup' ]
    [:min, :avg, :max, :stddev].each_with_index do |stat, index|
      g.data stat, @stats[stat]
      hash[index] = pages[index]
    end

    g.labels = hash
    g.write "httperf_log.png"
  end

  def print_stats
    #puts "Aggregate Reply rate [replies/s]: min #{format_float @stats[:min].min} avg #{format_float @stats[:avg].average} max #{format_float @stats[:max].max} stddev #{format_float @stats[:stddev].average}"
  end

  def format_float(value)
    "%0.1f" % value
  end

end

ParseHttperfLog.run
