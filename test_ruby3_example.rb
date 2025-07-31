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
  cleaned = sanitize(input)
  return cleaned
end

def parse_url(url)
  if match = url.match(/https?:\/\/(?<host>\w+):(?<port>\d+)/)
    host = match[:host]
    port = match[:port].to_i
    return { host: host, port: port }
  end
end