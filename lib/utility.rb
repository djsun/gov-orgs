require 'rubygems'
require 'yaml'
require 'open-uri'
require 'nokogiri'
require 'sha1'
require File.expand_path('omap', File.dirname(__FILE__))
require File.expand_path('validator', File.dirname(__FILE__))

class Utility
  
  def self.fetch(uri)
    puts "Fetching: #{uri}"
    io = open(uri, headers)
    io.read
  end

  def self.headers
    {
      "UserAgent" => "Government Organization Importer/0.1.0",
    }
  end
  
  FLUSH_AFTER = 25
  
  def self.modify_each_org(master_filename, temp_filename, verbose=true)
    i = 0
    puts "Reading #{master_filename}..." if verbose
    File.open(master_filename) do |f_in|
      puts "Creating #{temp_filename}..." if verbose
      File.open(temp_filename, 'w') do |f_out|
        YAML.load_documents(f_in) do |org|
          if verbose
            print "."
            STDOUT.flush if i % FLUSH_AFTER == 0
          end
          i += 1
          if org['versions'][0]['deleted'] != true
            yield(org)
          end
          YAML.dump(org, f_out)
        end
      end
    end
    Validator.new(:filename => temp_filename).run
    puts "\nDeleting #{master_filename}..." if verbose
    File.delete(master_filename)
    puts "Renaming #{temp_filename} to #{master_filename}..." if verbose
    File.rename(temp_filename, master_filename)
  end
  
  def self.parse_file(filename)
    File.open(filename) do |f|
      Nokogiri::HTML(f)
    end
  end

  def self.parse_uri(uri)
    puts "Fetching and parsing: #{uri}"
    open(uri, headers) do |io|
      Nokogiri::HTML(io)
    end
  end
  
  def self.time_format(t)
    t.strftime('%Y-%m-%d %H:%M:%S %z')
  end
  
  def self.uid(s)
    SHA1.sha1(s).to_s
  end
  
  def self.write_yaml(filename, documents)
    File.open(filename, "w") do |f|
      documents.each do |document|
        YAML.dump(document, f)
      end
    end
  end
  
end
