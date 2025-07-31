class LegacyClass
  def check_number(num)
    if num.is_a?(Fixnum)
      return TRUE
    elsif num.is_a?(Bignum)
      return FALSE
    end
    return NIL
  end
end

def process_data(input)
  input.taint
  cleaned = sanitize(input)
  cleaned.untaint
  input.trust
  return cleaned
end

def parse_url(url)
  if url =~ /https?:\/\/(\w+):(\d+)/
    host = $1
    port = $2.to_i
    return { host: host, port: port }
  end
end