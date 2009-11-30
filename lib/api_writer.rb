require File.expand_path('utility', File.dirname(__FILE__))
require File.expand_path('simplify_omap', File.dirname(__FILE__))

class ApiWriter
  
  class Error < RuntimeError; end
    
  FIELDS = %w(
    api_key
    base_uri
    log_filename
    orgs_filename
    time_delay
  )
  
  FIELDS.each { |f| attr_accessor f.intern }
  
  def initialize(options)
    FIELDS.each do |f|
      self.send(:"#{f}=", options[f.intern])
    end
  end
  
  def run
    validate
    setup
    Utility.setup_api(api_key, base_uri)
    process_orgs
    finish
  end
  
  protected
  
  def setup
    @log = File.open(log_filename, 'w')
    @error_count = 0
  end
  
  def finish
    @log.close
    if @error_count > 0
      puts "There were #{@error_count} import errors."
      puts "See #{log_filename} for details."
    end
  end
  
  def process_orgs(verbose=false)
    count = 0
    Utility.each_org(orgs_filename, verbose) do |org|
      latest_version = org['versions'][0]
      data = latest_version['data']
      names = data['names']
      urls = data['urls']
      params = {
        :name        => names[0],
        :names       => names,
        :acronym     => "",
        :org_type    => "governmental",
        :description => "",
        :raw         => org.simplify,
      }
      params[:url] = urls[0] if urls
      create_organization(params)
      print "."
      STDOUT.flush if count % 25 == 0
      count += 1
      sleep(time_delay)
    end
    puts ""
  end
  
  def create_organization(params)
    begin
      DataCatalog::Organization.create(params)
    rescue DataCatalog::BadRequest => message
      @error_count += 1
      YAML.dump(YAML::Omap[
        'error', message,
        'params', params
      ], @log)
    end
  end
  
  def validate
    FIELDS.each do |f|
      raise Error, "Missing #{f}" unless send(:"#{f}")
    end
  end
  
end
