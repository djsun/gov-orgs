require File.expand_path('migrations', File.dirname(__FILE__))
require File.expand_path('utility', File.dirname(__FILE__))

class MergeMigrationExtractor

  class Error < RuntimeError; end

  FIELDS = %w(
    merge_log_filename
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
    
  TEMPLATE_FILENAME = expand('../templates/merge_migration_template.rb')

  def run
    validate
    FileUtils.copy(merge_log_filename, Migrations.next_filename('merge', 'yaml'))
    FileUtils.copy(TEMPLATE_FILENAME, Migrations.next_filename('merge'))
  end
  
  protected
  
  def validate
    FIELDS.each do |f|
      raise Error, "Missing #{f}" unless send(:"#{f}")
    end
  end

end
