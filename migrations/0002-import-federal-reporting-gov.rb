require 'rubygems'
require 'fastercsv'

require File.expand_path("../lib/utility", File.dirname(__FILE__))
require File.expand_path("../lib/validator", File.dirname(__FILE__))

class FederalRegisterImporter

  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  MASTER_FILE = expand('../data/orgs.yaml')
  IMPORT_FILE = expand('0002-orgs_and_codes.txt')

  def run
    load_import_file
    build_lookup_hashes
    append_to_master_file
    Validator.new(:filename => MASTER_FILE).run
  end
  
  protected
  
  def load_import_file
    @import_time = Time.now
    @rows = FasterCSV.read(IMPORT_FILE, :col_sep => "\t")
  end
  
  def build_lookup_hashes
    @names, @uids = {}, {}
    @rows.each do |row|
      code, name = row[0], row[1]
      @names[code] = name
      @uids[code]  = Utility.uid("#{name} #{code}")
    end
  end
  
  def append_to_master_file
    inserts = 0
    File.open(MASTER_FILE, 'a') do |f|
      @rows.each do |row|
        code, name = row[0], row[1]
        org = build_org(name, code, @import_time)
        YAML.dump(org, f)
        inserts += 1
      end
    end
    puts '%i inserts' % [inserts]
  end
  
  IMPORT_URI = 'https://www.federalreporting.gov/federalreporting/agencyCodes.do'
  
  def build_org(name, code, time)
    parent_uid = @uids[parent_code(code)]
    data = YAML::Omap[
      'names',                [name],
      'parents',              parent_uid ? [parent_uid] : [],
      'federalreporting.gov', YAML::Omap[
        'names', [name],
        'codes', [code],
      ],
    ]
    
    YAML::Omap[
      'uid',      @uids[code],
      'versions', [
        YAML::Omap[
          'data',       data,
          'time',       Utility.time_format(time),
          'who',        File.basename(__FILE__),
          'source_uri', IMPORT_URI,
        ]
      ]
    ]
  end
  
  def parent_code(code)
    raise "unexpected format" unless /\w{4}/ =~ code
    code[0,2] + '00'
  end

end

importer = FederalRegisterImporter.new
importer.run
