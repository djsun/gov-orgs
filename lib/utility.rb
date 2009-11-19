require 'rubygems'
require 'yaml'
require 'open-uri'
require 'nokogiri'
require 'sha1'
require File.expand_path('omap', File.dirname(__FILE__))

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
