#!/usr/bin/env ruby
# encoding: utf-8

require 'optparse'
require 'colorize'
require_relative 'lib/migrator'

class RubyMigratorCLI
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
    
    puts "Ruby 2 to Ruby 3 Migration Tool".colorize(:blue).bold
    puts "=" * 40
    
    migrator = Migrator.new(@options)
    
    begin
      if @options[:report_only]
        puts "Analyzing project for Ruby 3 compatibility issues...".colorize(:yellow)
        migrator.analyze_only
      else
        puts "Starting migration process...".colorize(:green)
        migrator.migrate
      end
      
      puts "\nMigration completed successfully!".colorize(:green).bold
    rescue => e
      puts "\nError during migration: #{e.message}".colorize(:red)
      puts e.backtrace.join("\n") if @options[:verbose]
      exit 1
    end
  end

  private

  def parse_options
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby ruby_migrator.rb [options]"
      
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

# Run the CLI if this file is executed directly
if __FILE__ == $0
  RubyMigratorCLI.new.run
end
