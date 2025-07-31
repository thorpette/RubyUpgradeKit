#!/usr/bin/env ruby

# Ejemplo de código Ruby 2 con problemas de compatibilidad

class LegacyApplication
  def initialize
    @data = Hash["key1", "value1", "key2", "value2"]
    @numbers = [1, 2, 3]
  end

  # Uso de constantes removidas en Ruby 3
  def check_types(value)
    case value.class
    when Fixnum
      puts "Es un número entero pequeño"
    when Bignum
      puts "Es un número entero grande"
    when String
      puts "Es una cadena"
    end
  end

  # Métodos removidos en Ruby 3
  def secure_data(input)
    input.taint
    process_data(input)
    input.untaint
    input
  end

  def trust_data(input)
    input.trust
    validate_input(input)
    input.untrust if input.respond_to?(:untrust)
  end

  # Sintaxis de hash antigua
  def old_hash_syntax
    config = {
      host: "localhost",
      port: 3000,
      ssl: TRUE,
      debug: FALSE
    }
    
    return config
  end

  # Uso de variables globales que cambiaron
  def parse_string(text)
    if text =~ /(\w+):(\d+)/
      host = $1
      port = $2.to_i
      puts "Host: #{host}, Port: #{port}"
    end
  end

  # Concatenación de strings que podría mejorarse
  def generate_message(name, age)
    message = "Hola " + name + ", tienes " + age.to_s + " años"
    puts message
  end

  # Uso de proc que cambió comportamiento
  def test_proc
    my_proc = proc { |x, y| x + y }
    result = my_proc.call(1) # Esto puede fallar en Ruby 3
    puts result
  end

  # Uso de lambda con argumentos incorrectos
  def test_lambda
    my_lambda = lambda { |x, y| x * y }
    result = my_lambda.call(5) # Error en Ruby 3
    puts result
  end

  # Uso de constantes globales removidas
  def check_nil_values(value)
    return NIL if value.nil?
    return TRUE if value == true
    return FALSE if value == false
    value
  end

  private

  def process_data(data)
    # Simular procesamiento
    data.chomp!
    data.gsub!(/\s+/, ' ')
  end

  def validate_input(input)
    # Validación simple
    !input.empty?
  end
end

# Ejemplo de uso
app = LegacyApplication.new
app.check_types(42)
app.old_hash_syntax
app.parse_string("server:8080")
app.generate_message("Juan", 25)