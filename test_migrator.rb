#!/usr/bin/env ruby
# encoding: utf-8

puts "Probando Ruby migrator..."

begin
  require_relative 'lib/file_scanner'
  
  scanner = FileScanner.new('.')
  files = scanner.scan_ruby_files
  
  puts "Archivos Ruby encontrados: #{files.length}"
  files.each do |file|
    puts "  - #{file}"
  end
  
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
end