#!/usr/bin/env ruby
# encoding: utf-8

# Suprimir warnings específicos
def suppress_warnings
  original_stderr = $stderr
  $stderr = StringIO.new
  begin
    yield
  ensure
    $stderr = original_stderr
  end
end

require 'stringio'

# Cargar dependencias suprimiendo warnings
suppress_warnings do
  require 'optparse'
  require 'colorize'
  require_relative 'lib/migrator'
end

class CleanRubyMigratorCLI
  def initialize
    @options = {
      path: '.',
      report_only: false,
      backup: true,
      output_format: 'text',
      verbose: false
    }
  end

  def run
    parse_options
    
    puts "\n🚀 Ruby 2 to Ruby 3 Migration Tool".colorize(:blue).bold
    puts "=" * 50
    
    migrator = Migrator.new(@options)
    
    begin
      if @options[:report_only]
        puts "📊 Analyzing project for Ruby 3 compatibility issues...".colorize(:yellow)
        migrator.analyze_only
      else
        puts "🔧 Starting migration process...".colorize(:green)
        migrator.migrate
      end
      
      puts "\n✅ Migration completed successfully!".colorize(:green).bold
    rescue => e
      puts "\n❌ Error during migration: #{e.message}".colorize(:red)
      puts e.backtrace.join("\n") if @options[:verbose]
      exit 1
    end
  end

  private

  def parse_options
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby clean_migrator.rb [options]"
      
      opts.on("-p", "--path PATH", "Project path to analyze (default: current directory)") do |path|
        @options[:path] = path
      end
      
      opts.on("-r", "--report-only", "Generate report only, don't apply changes") do
        @options[:report_only] = true
      end
      
      opts.on("--no-backup", "Skip creating backup files") do
        @options[:backup] = false
      end
      
      opts.on("-f", "--format FORMAT", "Output format: text, json (default: text)") do |format|
        @options[:output_format] = format
      end
      
      opts.on("-v", "--verbose", "Verbose output") do
        @options[:verbose] = true
      end
      
      opts.on("-h", "--help", "Show this help") do
        puts opts
        exit
      end
    end.parse!
  end
end

# Ejecutar sin warnings
suppress_warnings do
  if __FILE__ == $0
    CleanRubyMigratorCLI.new.run
  end
end