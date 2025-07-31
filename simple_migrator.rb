#!/usr/bin/env ruby
# encoding: utf-8

# Migrador Ruby 2 a Ruby 3 - Versión Simplificada
# Sin dependencias externas problemáticas

require 'optparse'
require 'json'
require 'fileutils'
require 'find'

class SimpleMigrator
  def initialize(options = {})
    @options = {
      path: '.',
      report_only: false,
      backup: true,
      output_format: 'text',
      verbose: false
    }.merge(options)
    
    @issues = []
    @patterns = load_patterns
  end

  def run
    puts "\n=== Ruby 2 to Ruby 3 Migration Tool ==="
    puts "Starting analysis of: #{@options[:path]}"
    
    files = find_ruby_files(@options[:path])
    puts "Found #{files.length} Ruby files"
    
    if files.empty?
      puts "No Ruby files found to analyze"
      return
    end
    
    # Crear backup si es necesario
    create_backup(files) if @options[:backup] && !@options[:report_only]
    
    # Analizar archivos
    files.each_with_index do |file, index|
      progress = ((index + 1).to_f / files.length * 100).round(1)
      puts "[#{progress}%] Analyzing: #{file}"
      analyze_file(file)
    end
    
    # Generar reporte
    generate_report
    
    puts "\nAnalysis completed successfully!"
    puts "Total issues found: #{@issues.length}"
  end

  private

  def find_ruby_files(path)
    files = []
    
    if File.file?(path) && path.end_with?('.rb')
      return [path]
    end
    
    return [] unless File.directory?(path)
    
    Find.find(path) do |file_path|
      # Excluir directorios problemáticos
      if File.directory?(file_path)
        dir_name = File.basename(file_path)
        if %w[.git .ruby_migration_backup node_modules .bundle vendor].include?(dir_name)
          Find.prune
        end
        next
      end
      
      # Incluir archivos Ruby
      if file_path.end_with?('.rb', '.rake', '.gemspec') || 
         File.basename(file_path) =~ /^(Rakefile|Gemfile)$/
        files << file_path
      end
    end
    
    files.sort
  end

  def load_patterns
    {
      deprecated_constants: [
        { pattern: /\b(Fixnum|Bignum)\b/, replacement: 'Integer', severity: 'ERROR' },
        { pattern: /\b(TRUE|FALSE|NIL)\b/, replacement: 'true/false/nil', severity: 'ERROR' }
      ],
      deprecated_methods: [
        { pattern: /\.taint\b/, replacement: 'Remove taint/untaint calls', severity: 'ERROR' },
        { pattern: /\.untaint\b/, replacement: 'Remove taint/untaint calls', severity: 'ERROR' },
        { pattern: /\.trust\b/, replacement: 'Remove trust/untrust calls', severity: 'ERROR' },
        { pattern: /\.untrust\b/, replacement: 'Remove trust/untrust calls', severity: 'ERROR' }
      ],
      syntax_changes: [
        { pattern: /:(\w+)\s*=>\s*/, replacement: 'Use new hash syntax', severity: 'WARNING' },
        { pattern: /\$[1-9]\d*/, replacement: 'Use local variables or named captures', severity: 'WARNING' }
      ],
      behavior_changes: [
        { pattern: /\bproc\s*\{/, replacement: 'Review proc usage for potential breaking changes', severity: 'INFO' },
        { pattern: /\blambda\s*\{/, replacement: 'Review lambda argument handling', severity: 'INFO' }
      ]
    }
  end

  def analyze_file(file_path)
    return unless File.readable?(file_path)
    
    begin
      content = File.read(file_path, encoding: 'utf-8')
      lines = content.lines
      
      lines.each_with_index do |line, line_num|
        @patterns.each do |category, patterns|
          patterns.each do |pattern_info|
            if line.match(pattern_info[:pattern])
              @issues << {
                file: file_path,
                line: line_num + 1,
                code: line.strip,
                pattern: pattern_info[:pattern].source,
                fix: pattern_info[:replacement],
                severity: pattern_info[:severity],
                category: category.to_s
              }
            end
          end
        end
      end
    rescue => e
      puts "Warning: Could not read #{file_path}: #{e.message}" if @options[:verbose]
    end
  end

  def create_backup(files)
    backup_dir = File.join(@options[:path], '.ruby_migration_backup')
    puts "Creating backup in #{backup_dir}..."
    
    files.each do |file|
      relative_path = file.sub(@options[:path], '').sub(/^\//, '')
      backup_path = File.join(backup_dir, relative_path)
      
      FileUtils.mkdir_p(File.dirname(backup_path))
      FileUtils.copy(file, backup_path)
    end
    
    puts "Backup created successfully"
  end

  def generate_report
    if @options[:output_format] == 'json'
      generate_json_report
    else
      generate_text_report
    end
  end

  def generate_text_report
    puts "\n" + "=" * 60
    puts "Ruby 2 to Ruby 3 Compatibility Report"
    puts "=" * 60
    puts "Project: #{@options[:path]}"
    puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "Total Issues: #{@issues.length}"
    
    %w[ERROR WARNING INFO].each do |severity|
      issues = @issues.select { |i| i[:severity] == severity }
      next if issues.empty?
      
      puts "\n#{severity} (#{issues.length})"
      puts "-" * 30
      
      issues.each do |issue|
        puts "#{issue[:file]}:#{issue[:line]}:1 - #{get_issue_description(issue)}"
        puts "  Code: #{issue[:code]}"
        puts "  Fix: #{issue[:fix]}"
        puts
      end
    end
    
    puts "Summary & Recommendations:"
    puts "-" * 30
    error_count = @issues.count { |i| i[:severity] == 'ERROR' }
    warning_count = @issues.count { |i| i[:severity] == 'WARNING' }
    
    puts "#{error_count} critical issues require manual attention" if error_count > 0
    puts "#{warning_count} warnings should be reviewed" if warning_count > 0
    
    puts "\nNext Steps:"
    puts "1. Address critical errors first"
    puts "2. Review and fix warnings"
    puts "3. Test your application thoroughly"
    puts "4. Update dependencies to Ruby 3 compatible versions"
  end

  def generate_json_report
    report = {
      project: @options[:path],
      generated: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      total_issues: @issues.length,
      issues: @issues,
      summary: {
        errors: @issues.count { |i| i[:severity] == 'ERROR' },
        warnings: @issues.count { |i| i[:severity] == 'WARNING' },
        info: @issues.count { |i| i[:severity] == 'INFO' }
      }
    }
    
    puts JSON.pretty_generate(report)
  end

  def get_issue_description(issue)
    case issue[:pattern]
    when /Fixnum|Bignum/
      "#{issue[:pattern].match(/\w+/)[0]} class has been removed in Ruby 3"
    when /taint|untaint|trust|untrust/
      "#{issue[:pattern].sub(/[\\.]/, '')} method has been removed in Ruby 3"
    when /\$[1-9]/
      "Global match variables behavior changed"
    when /proc|lambda/
      "#{issue[:pattern].match(/\w+/)[0].capitalize} behavior changed in Ruby 3"
    else
      "Ruby 3 compatibility issue detected"
    end
  end
end

class SimpleMigratorCLI
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
    migrator = SimpleMigrator.new(@options)
    migrator.run
  end

  private

  def parse_options
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby simple_migrator.rb [options]"
      
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

# Ejecutar si es el archivo principal
if __FILE__ == $0
  SimpleMigratorCLI.new.run
end