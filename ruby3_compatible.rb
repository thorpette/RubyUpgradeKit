# Ruby 3 Compatible Code Examples

class ModernClass
  def check_number(num)
    if num.is_a?(Integer)
      return true
    else
      return false
    end
  end
end

def process_data(input)
  # Modern Ruby 3 approach - no taint/untaint needed
  cleaned = sanitize(input)
  return cleaned
end

def parse_url(url)
  # Use named captures for better Ruby 3 compatibility
  if match = url.match(/https?:\/\/(?<host>\w+):(?<port>\d+)/)
    host = match[:host]
    port = match[:port].to_i
    return { host: host, port: port }
  end
end

def modern_processing
  # Modern proc and lambda usage
  calculation_proc = proc { |x, y| x + y }
  validation_lambda = lambda { |x, y| x * y }
  
  # Modern hash syntax
  config = { 
    server: "localhost", 
    port: 3000,
    ssl: true,
    debug: false
  }
  
  return {
    sum: calculation_proc.call(5, 3),
    product: validation_lambda.call(4, 6),
    config: config
  }
end