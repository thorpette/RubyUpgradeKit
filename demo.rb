#!/usr/bin/env ruby

puts "=== Demostración Ruby Migrator ==="
puts "La utilidad está funcionando correctamente!"
puts

# Ejemplo 1: Análisis solo (sin modificar archivos)
puts "1. Análisis de carpeta examples (solo reporte):"
system("ruby ruby_migrator.rb -p examples -r")

puts "\n" + "="*50

# Ejemplo 2: Mostrar ayuda
puts "2. Opciones disponibles:"
system("ruby ruby_migrator.rb --help")

puts "\n=== Utilidad lista para usar ==="