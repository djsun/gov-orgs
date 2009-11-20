require File.expand_path('utility', File.dirname(__FILE__))
require File.expand_path('validator', File.dirname(__FILE__))

class DiffMigration

  class Error < RuntimeError; end
  class ValidationError < Error; end

  FIELDS = %w(
    orgs_filename
    diff_filename
  )
  
  FIELDS.each { |f| attr_accessor f.intern }

  def initialize(options)
    FIELDS.each do |f|
      self.send(:"#{f}=", options[f.intern])
    end
  end
  
  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  TEMP_FILENAME = expand('../data/orgs_temp.yaml')
  
  def run
    validate
    diffs = org_diffs_by_uid(diff_filename)
    File.open(orgs_filename) do |f_in|
      File.open(TEMP_FILENAME, "w") do |f_out|
        YAML.load_documents(f_in) do |org|
          uid = org['uid']
          if diffs[uid]
            puts "Merging uid : #{uid}"
            org['versions'].insert(0, diffs[uid])
          end
          YAML.dump(org, f_out)
        end
      end
    end
    unless File.delete(orgs_filename) == 1
      raise Error
    end
    File.rename(TEMP_FILENAME, orgs_filename)
  end
  
  protected
  
  def org_diffs_by_uid(filename)
    diffs = {}
    File.open(filename) do |f|
      YAML.load_documents(f) do |diff|
        diffs[diff['uid']] = diff['new_version']
      end
    end
    diffs
  end

  
  def validate
    FIELDS.each do |f|
      raise ValidationError, "Missing #{f}" unless send(:"#{f}")
    end
  end
  
end
