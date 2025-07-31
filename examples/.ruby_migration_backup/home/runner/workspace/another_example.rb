# Otro ejemplo con más patrones problemáticos

class DatabaseHelper
  def initialize
    # Hash con sintaxis antigua
    @config = {
      :database => "production",
      :timeout => 30,
      :retry_count => 3
    }
  end

  # Más uso de constantes removidas
  def validate_number(num)
    if num.is_a?(Fixnum)
      return TRUE
    elsif num.is_a?(Bignum) 
      return FALSE
    else
      return NIL
    end
  end

  # Métodos de taint/trust
  def sanitize_input(user_input)
    user_input.taint
    cleaned = user_input.strip
    cleaned.untaint
    cleaned
  end

  # Concatenación de strings
  def build_query(table, field, value)
    query = "SELECT * FROM " + table + " WHERE " + field + " = '" + value + "'"
    return query
  end

  # Uso problemático de proc
  def map_data(data)
    mapper = proc { |item| item.upcase }
    data.map(&mapper)
  end
end