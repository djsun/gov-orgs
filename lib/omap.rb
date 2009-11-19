require 'yaml'

module YAML
  
  class Omap
    def deep_clone
      o = self.class.new
      self.each do |x|
        o[x[0]] = case x[1]
        when Omap
          x[1].deep_clone
        else
          x[1].clone
        end
      end
      o
    end
    
    def merge(b)
      a = self.deep_clone
      keys = b.map { |x| x[0] }
      keys.each do |key|
        if a[key] && !b[key]
          # nothing
        elsif !a[key] && b[key]
          a[key] = b[key]
        else
          a[key] =
            case a[key]
            when Omap
              a[key].merge(b[key])
            when Array
              (a[key] + b[key]).uniq
            else raise "unexpected"
            end
        end
      end
      a
    end
  end

end
