class Migrations
  
  PATH = File.expand_path("../migrations", File.dirname(__FILE__))
  DIR = File.join(PATH, "*.rb")
  ORGS_FILE = File.expand_path('../data/orgs.yaml', File.dirname(__FILE__))
  
  def self.basenames
    filenames.map { |f| File.basename(f) }
  end
  
  def self.filenames
    Dir.glob(DIR).sort
  end

  def self.next_basename(s, ext="rb")
    '%04i-%s.%s' % [next_number, s, ext]
  end

  def self.next_filename(s, ext="rb")
    File.join(PATH, next_basename(s, ext))
  end
  
  def self.next_number
    /^\d*/ =~ basenames.last
    Regexp.last_match.to_s.to_i + 1
  end

  def self.run_all
    if File.exist?(ORGS_FILE)
      File.delete(ORGS_FILE)
    end
    filenames.each do |filename|
      puts "Running #{filename}..."
      load filename
    end
  end
  
end
