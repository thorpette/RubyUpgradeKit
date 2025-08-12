#!/usr/bin/env ruby
# ejemplos_tipado_ruby3.rb - Ejemplos prácticos del sistema de tipado Ruby 3

# Ejemplo 1: Clase básica con RBS
class Calculator
  def initialize
    @memory = 0.0
    @history = []
  end
  
  def add(a, b)
    result = a + b
    @history << "#{a} + #{b} = #{result}"
    result
  end
  
  def subtract(a, b)
    result = a - b
    @history << "#{a} - #{b} = #{result}"
    result
  end
  
  def multiply(a, b)
    result = a * b
    @history << "#{a} * #{b} = #{result}"
    result
  end
  
  def divide(a, b)
    raise ArgumentError, "Cannot divide by zero" if b == 0
    result = a / b.to_f
    @history << "#{a} / #{b} = #{result}"
    result
  end
  
  def store(value)
    @memory = value
  end
  
  def recall
    @memory
  end
  
  def clear_history
    @history.clear
  end
  
  def show_history
    @history
  end
end

# Ejemplo 2: Manejo de APIs con tipos
class WeatherService
  BASE_URL = "https://api.weather.com"
  
  def initialize(api_key)
    @api_key = api_key
    @last_response = nil
  end
  
  def get_current_weather(city)
    # Simulación de respuesta API
    {
      city: city,
      temperature: rand(15..35),
      humidity: rand(30..90),
      condition: ["sunny", "cloudy", "rainy"].sample,
      timestamp: Time.now
    }
  end
  
  def get_forecast(city, days = 5)
    forecast = []
    days.times do |i|
      forecast << {
        date: Date.today + i,
        high: rand(20..35),
        low: rand(5..20),
        condition: ["sunny", "cloudy", "rainy", "stormy"].sample
      }
    end
    forecast
  end
  
  def validate_city(city)
    return false if city.nil? || city.empty?
    city.length > 2 && city.match?(/\A[a-zA-Z\s]+\z/)
  end
end

# Ejemplo 3: Sistema de usuarios con validaciones
class User
  attr_reader :id, :name, :email, :created_at
  
  def initialize(id, name, email)
    @id = id
    @name = name
    @email = email
    @created_at = Time.now
    @preferences = {}
  end
  
  def update_name(new_name)
    return false if new_name.nil? || new_name.strip.empty?
    @name = new_name.strip
    true
  end
  
  def update_email(new_email)
    return false unless valid_email?(new_email)
    @email = new_email.downcase
    true
  end
  
  def set_preference(key, value)
    @preferences[key.to_sym] = value
  end
  
  def get_preference(key)
    @preferences[key.to_sym]
  end
  
  def to_h
    {
      id: @id,
      name: @name,
      email: @email,
      created_at: @created_at,
      preferences: @preferences
    }
  end
  
  def adult?
    return false unless @preferences[:age]
    @preferences[:age] >= 18
  end
  
  private
  
  def valid_email?(email)
    return false if email.nil?
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end
end

# Ejemplo 4: Sistema de productos con categorías
class Product
  CATEGORIES = %w[electronics clothing books home sports].freeze
  
  attr_reader :id, :name, :price, :category, :in_stock
  
  def initialize(id, name, price, category)
    @id = id
    @name = name
    @price = price.to_f
    @category = category
    @in_stock = true
    @tags = []
  end
  
  def update_price(new_price)
    return false if new_price <= 0
    @price = new_price.to_f
    true
  end
  
  def add_tag(tag)
    return false if tag.nil? || tag.empty?
    @tags << tag.downcase unless @tags.include?(tag.downcase)
    true
  end
  
  def remove_tag(tag)
    @tags.delete(tag.downcase)
  end
  
  def mark_out_of_stock
    @in_stock = false
  end
  
  def mark_in_stock
    @in_stock = true
  end
  
  def discounted_price(percentage)
    return @price if percentage <= 0 || percentage >= 100
    @price * (1 - percentage / 100.0)
  end
  
  def category_valid?
    CATEGORIES.include?(@category)
  end
  
  def to_h
    {
      id: @id,
      name: @name,
      price: @price,
      category: @category,
      in_stock: @in_stock,
      tags: @tags.dup
    }
  end
end

# Ejemplo 5: Sistema de carritos de compra
class ShoppingCart
  def initialize(user_id)
    @user_id = user_id
    @items = []
    @created_at = Time.now
  end
  
  def add_item(product, quantity = 1)
    return false if quantity <= 0
    
    existing_item = @items.find { |item| item[:product].id == product.id }
    
    if existing_item
      existing_item[:quantity] += quantity
    else
      @items << {
        product: product,
        quantity: quantity,
        added_at: Time.now
      }
    end
    true
  end
  
  def remove_item(product_id)
    @items.reject! { |item| item[:product].id == product_id }
  end
  
  def update_quantity(product_id, new_quantity)
    return false if new_quantity <= 0
    
    item = @items.find { |item| item[:product].id == product_id }
    return false unless item
    
    item[:quantity] = new_quantity
    true
  end
  
  def total_price
    @items.sum { |item| item[:product].price * item[:quantity] }
  end
  
  def total_items
    @items.sum { |item| item[:quantity] }
  end
  
  def apply_discount(percentage)
    return 0 if percentage <= 0 || percentage >= 100
    total_price * (percentage / 100.0)
  end
  
  def clear
    @items.clear
  end
  
  def to_h
    {
      user_id: @user_id,
      items: @items.map do |item|
        {
          product: item[:product].to_h,
          quantity: item[:quantity],
          subtotal: item[:product].price * item[:quantity],
          added_at: item[:added_at]
        }
      end,
      total_price: total_price,
      total_items: total_items,
      created_at: @created_at
    }
  end
end

# Ejemplo de uso y testing
if __FILE__ == $0
  puts "🧮 Ejemplos del Sistema de Tipado Ruby 3"
  puts "=" * 50
  
  # Test Calculator
  puts "\n📊 Calculator Example:"
  calc = Calculator.new
  puts calc.add(10, 5)      # 15
  puts calc.multiply(3, 4)  # 12
  calc.store(100)
  puts calc.recall          # 100
  puts "History: #{calc.show_history}"
  
  # Test WeatherService
  puts "\n🌤️  Weather Service Example:"
  weather = WeatherService.new("fake-api-key")
  current = weather.get_current_weather("Madrid")
  puts "Weather in #{current[:city]}: #{current[:temperature]}°C, #{current[:condition]}"
  
  forecast = weather.get_forecast("Barcelona", 3)
  puts "3-day forecast for Barcelona:"
  forecast.each do |day|
    puts "  #{day[:date]}: #{day[:low]}°C - #{day[:high]}°C, #{day[:condition]}"
  end
  
  # Test User
  puts "\n👤 User Example:"
  user = User.new(1, "John Doe", "john@example.com")
  user.set_preference(:age, 25)
  user.set_preference(:theme, "dark")
  puts "User: #{user.name} (#{user.email})"
  puts "Adult: #{user.adult?}"
  puts "Preferences: #{user.to_h[:preferences]}"
  
  # Test Product
  puts "\n📦 Product Example:"
  product = Product.new(1, "Laptop", 999.99, "electronics")
  product.add_tag("portable")
  product.add_tag("work")
  puts "Product: #{product.name} - $#{product.price}"
  puts "Category valid: #{product.category_valid?}"
  puts "With 10% discount: $#{product.discounted_price(10)}"
  
  # Test ShoppingCart
  puts "\n🛒 Shopping Cart Example:"
  cart = ShoppingCart.new(user.id)
  
  # Crear más productos
  mouse = Product.new(2, "Wireless Mouse", 29.99, "electronics")
  book = Product.new(3, "Ruby Programming", 39.99, "books")
  
  # Agregar items al carrito
  cart.add_item(product, 1)
  cart.add_item(mouse, 2)
  cart.add_item(book, 1)
  
  puts "Cart total: $#{cart.total_price}"
  puts "Total items: #{cart.total_items}"
  puts "Discount (15%): $#{cart.apply_discount(15)}"
  
  puts "\n📋 Cart Summary:"
  cart_data = cart.to_h
  cart_data[:items].each do |item|
    puts "  #{item[:product][:name]} x#{item[:quantity]} = $#{item[:subtotal]}"
  end
  
  puts "\n✅ Todos los ejemplos ejecutados correctamente"
  puts "💡 Para usar con tipado, crea archivos .rbs correspondientes"
end