require File.expand_path("../lib/utility", File.dirname(__FILE__))
require File.expand_path("../lib/validator", File.dirname(__FILE__))

class UsaGovImporter

  class Error < RuntimeError; end
  class ValidationError < Error; end

  FIELDS = %w(
    base_uri
    org_selector
    other_uri_selector
    output_filename
    starting_path
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
    orgs = fetch_organizations
    sorted = sort(orgs)
    write_yaml(sorted)
    Validator.new({
      :filename => File.expand_path('../data/orgs.yaml', File.dirname(__FILE__))
    }).run
  end
  
  protected
  
  def fetch_organizations
    uri = full_uri(starting_path)
    doc = Utility.parse_uri(uri)
    orgs = []
    uris = get_page_uris(doc)
    puts "Found #{uris.length} pages to parse."
    uris.each do |uri|
      doc = Utility.parse_uri(uri)
      orgs.concat(get_organizations(doc, uri))
      sleep(time_delay)
    end
    orgs
  end
  
  def full_uri(path)
    URI.parse(base_uri).merge(path).to_s
  end

  def get_organizations(doc, uri)
    time = Time.now
    doc.css(org_selector).map do |x|
      url = make_absolute_url(x['href'])
      data = YAML::Omap[
        'names', [x.content],
        'urls',  [url],
      ]
      signature = "#{x.content} #{x['href']}"
      YAML::Omap[
        'uid',      Utility.uid(signature),
        'versions', [
          YAML::Omap[
            'data',       data,
            'time',       Utility.time_format(time),
            'who',        File.basename(__FILE__),
            'import_uri', uri,
          ]
        ]
      ]
    end
  end
  
  def make_absolute_url(raw_url)
    url = raw_url.strip
    uri = URI.parse(url)
    unless uri.absolute?
      uri = URI.parse(base_uri + url)
    end
    uri.to_s
  end
  
  def get_page_uris(doc)
    doc.css(other_uri_selector).map { |x| full_uri(x['href']) }.uniq
  end

  def validate
    FIELDS.each do |f|
      raise ValidationError, "Missing #{f}" unless send(:"#{f}")
    end
  end

  def sort(orgs)
    orgs.sort_by do |x|
      x['versions'][0]['data']['names'][0]
    end
  end
  
  def write_yaml(documents)
    full_filename = File.expand_path(output_filename, File.dirname(__FILE__))
    dir = File.dirname(full_filename)
    FileUtils.mkdir_p(dir) unless File.exists?(dir)
    Utility.write_yaml(full_filename, documents)
  end
  
end

importer = UsaGovImporter.new({
  :base_uri           => "http://www.usa.gov",
  :other_uri_selector => "div.a_z_List > a",
  :output_filename    => "../data/orgs.yaml",
  :org_selector       => "div.arrow_List > ul > li > a",
  :starting_path      => "/Agencies/Federal/All_Agencies/index.shtml",
  :time_delay         => 1,
})

importer.run
