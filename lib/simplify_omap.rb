require 'yaml'

class Object
  def simplify
    self
  end
end

class Array
  def simplify
    self.map { |e| e.simplify }
  end
end

class Hash
  def simplify
    simpler = {}
    self.each do |key, value|
      simpler[key] = value.simplify
    end
    simpler
  end
end

module YAML
  class Omap
    def simplify
      simpler = {}
      self.each do |key, value|
        simpler[key] = value.simplify
      end
      simpler
    end
  end
end
