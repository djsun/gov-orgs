require File.expand_path('utility', File.dirname(__FILE__))
require File.expand_path('simplify_omap', File.dirname(__FILE__))

class ApiWriter
  
  class Error < RuntimeError; end
    
  FIELDS = %w(
    api_key
    base_uri
    time_delay
    orgs_filename
  )
  
  FIELDS.each { |f| attr_accessor f.intern }
  
  def initialize(options)
    FIELDS.each do |f|
      self.send(:"#{f}=", options[f.intern])
    end
  end
  
  def run
    validate
    Utility.setup_api(api_key, base_uri)
    process_orgs
  end
  
  protected
  
  def process_orgs(verbose=false)
    count = 0
    Utility.each_org(orgs_filename, verbose) do |org|
      latest_version = org['versions'][0]
      data = latest_version['data']
      names = data['names']
      DataCatalog::Organization.create({
        :name        => names[0],
        :acronym     => "",
        :org_type    => "governmental",
        :description => "",
        :raw         => org.simplify,
      })
      print "."
      STDOUT.flush if count % 25 == 0
      count += 1
      sleep(time_delay)
    end
    puts ""
  end
  
  def validate
    FIELDS.each do |f|
      raise Error, "Missing #{f}" unless send(:"#{f}")
    end
  end
  
end
