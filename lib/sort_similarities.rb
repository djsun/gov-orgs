require 'rubygems'
require 'fastercsv'

class SimilaritySorter
  
  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end

  IN_FILE  = expand('../data/similarities.csv')
  OUT_FILE = expand('../data/similarities_sorted.csv')
  THRESHOLD = 0.50

  def run
    setup
    do_sort
    write_file
  end

  def setup
    puts 'Reading similarity file...'
    @similarites = FasterCSV.read(IN_FILE)
    raise unless @similarites
    puts '%i rows imported.' % [@similarites.length]
  end

  def do_sort
    puts 'Sort started.'
    @sorted = @similarites.sort_by { |x| -x[2].to_f }
    puts 'Sort finished.'
  end

  def write_file
    @sim_file = File.open(OUT_FILE, 'w')
    raise "Could not open file" unless @sim_file
    puts 'Writing sorted results...'
    @sorted.each do |row|
      if row[2].to_f >= THRESHOLD
        @sim_file.puts('%s,%s,%s' % [row[0], row[1], row[2]])
      end
    end
    @sim_file.close
  end
  
end
