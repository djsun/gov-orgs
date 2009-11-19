require 'yaml'

class BackerUpper
  
  class Error < RuntimeError; end
  
  FIELDS = %w(
    input_filename
    output_filename
  )

  FIELDS.each { |f| attr_accessor f.intern }

  def initialize(options)
    FIELDS.each do |f|
      self.send(:"#{f}=", options[f.intern])
    end
  end

  def run
    validate
    FileUtils.copy(input_filename, output_filename)
  end
  
  protected

  def validate
    FIELDS.each do |f|
      raise Error, "Missing #{f}" unless send(:"#{f}")
    end
  end

end
