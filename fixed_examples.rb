# Fixed Ruby 3 Compatible Code Examples

class LegacyClass
  def check_number(num)
    if num.is_a?(Integer)  # Fixed: Fixnum removed, use Integer
      return true          # Fixed: TRUE removed, use true
    elsif num.is_a?(Integer)  # Fixed: Bignum removed, use Integer  
      return false         # Fixed: FALSE removed, use false
    end
    return nil             # Fixed: NIL removed, use nil
  end
end

def process_data(input)
  # Fixed: taint/untaint methods removed in Ruby 3
  # These methods provided no real security and were removed
  cleaned = sanitize(input)
  return cleaned
end

# Additional Ruby 3 compatible examples
def parse_url(url)
  # Fixed: Use named captures instead of global variables
  if match = url.match(/https?:\/\/(\w+):(\d+)/)
    host = match[1]  # Fixed: Instead of $1
    port = match[2].to_i  # Fixed: Instead of $2
    return { host: host, port: port }
  end
end

def advanced_processing
  # Fixed: Modern proc and lambda usage
  my_proc = proc { |x, y| x + y }  # Proc behavior is consistent
  my_lambda = lambda { |x, y| x * y }  # Lambda argument checking is stricter
  
  # Fixed: Modern hash construction
  data = { key1: "value1", key2: "value2" }  # Instead of Hash["key1", "value1"]
  
  return {
    proc_result: my_proc.call(5, 3),
    lambda_result: my_lambda.call(4, 6),
    data: data
  }
end