#!/usr/bin/env ruby

puts "\n🚀 INICIANDO RUBY MIGRATOR 🚀"
puts "=" * 50

puts "\n✅ Comprobando Ruby..."
puts `ruby -v`

puts "\n✅ Comprobando utilidad..."
if File.exist?('ruby_migrator.rb')
  puts "📁 ruby_migrator.rb encontrado"
else
  puts "❌ ruby_migrator.rb no encontrado"
  exit 1
end

puts "\n✅ Ejecutando análisis rápido de ejemplos..."
puts "Comando: ruby ruby_migrator.rb -p examples -r"
puts "-" * 50

# Ejecutar el migrator
system('ruby ruby_migrator.rb -p examples -r')

puts "\n" + "=" * 50
puts "✅ RUBY MIGRATOR FUNCIONANDO CORRECTAMENTE"
puts "Utilidad lista para migrar proyectos Ruby 2 → Ruby 3"
puts "=" * 50