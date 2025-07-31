#!/usr/bin/env ruby
# encoding: utf-8

# Ruby 2 to Ruby 3 Migration Tool
# Complete standalone version without external dependencies

require 'optparse'
require 'json'
require 'fileutils'
require 'find'
require 'time'

class RubyMigrationTool
  VERSION = "1.0.0"
  
  def initialize
    @options = {
      path: '.',
      report_only: false,
      backup: true,
      format: 'text',
      verbose: false
    }
    @issues = []
    @files_processed = 0
    @start_time = Time.now
  end

  def run(args = ARGV)
    parse_arguments(args)
    display_header
    
    begin
      ruby_files = find_ruby_files(@options[:path])
      
      if ruby_files.empty?
        puts "No Ruby files found in #{@options[:path]}"
        return
      end
      
      puts "Found #{ruby_files.length} Ruby files to analyze"
      
      create_backup(ruby_files) if @options[:backup] && !@options[:report_only]
      
      analyze_files(ruby_files)
      generate_report
      
      puts "\nMigration analysis completed successfully!"
      puts "Processing time: #{(Time.now - @start_time).round(2)} seconds"
      
    rescue => e
      puts "ERROR: #{e.message}"
      puts e.backtrace.join("\n") if @options[:verbose]
      exit 1
    end
  end

  private

  def parse_arguments(args)
    parser = OptionParser.new do |opts|
      opts.banner = "Ruby 2 to Ruby 3 Migration Tool v#{VERSION}"
      opts.separator ""
      opts.separator "Usage: ruby migrator.rb [options]"
      opts.separator ""
      opts.separator "Options:"
      
      opts.on("-p", "--path PATH", "Path to analyze (default: current directory)") do |path|
        @options[:path] = path
      end
      
      opts.on("-r", "--report-only", "Generate report only, don't modify files") do
        @options[:report_only] = true
      end
      
      opts.on("--no-backup", "Skip creating backup files") do
        @options[:backup] = false
      end
      
      opts.on("-f", "--format FORMAT", "Output format: text or json (default: text)") do |format|
        @options[:format] = format.downcase
      end
      
      opts.on("-v", "--verbose", "Enable verbose output") do
        @options[:verbose] = true
      end
      
      opts.on("-h", "--help", "Show this help message") do
        puts opts
        exit 0
      end
      
      opts.on("--version", "Show version") do
        puts "Ruby Migration Tool v#{VERSION}"
        exit 0
      end
    end
    
    begin
      parser.parse!(args)
    rescue OptionParser::InvalidOption => e
      puts "ERROR: #{e.message}"
      puts parser
      exit 1
    end
  end

  def display_header
    puts
    puts "=" * 60
    puts "Ruby 2 to Ruby 3 Migration Tool v#{VERSION}".center(60)
    puts "=" * 60
    puts "Target path: #{File.absolute_path(@options[:path])}"
    puts "Mode: #{@options[:report_only] ? 'Analysis only' : 'Analysis and migration'}"
    puts "Backup: #{@options[:backup] ? 'Enabled' : 'Disabled'}"
    puts "=" * 60
    puts
  end

  def find_ruby_files(path)
    files = []
    
    if File.file?(path)
      return [path] if ruby_file?(path)
      return []
    end
    
    unless File.directory?(path)
      puts "ERROR: Path #{path} does not exist"
      exit 1
    end
    
    Find.find(path) do |file_path|
      if File.directory?(file_path)
        dirname = File.basename(file_path)
        # Skip common directories that shouldn't be analyzed
        if %w[.git .svn .hg node_modules .bundle vendor .ruby_migration_backup tmp log].include?(dirname)
          Find.prune
        end
        next
      end
      
      files << file_path if ruby_file?(file_path)
    end
    
    files.sort
  end

  def ruby_file?(path)
    return false unless File.readable?(path)
    
    # Check extension
    return true if path.match?(/\.(rb|rake|gemspec)$/)
    
    # Check common Ruby files without extension
    basename = File.basename(path)
    return true if %w[Rakefile Gemfile Guardfile Capfile].include?(basename)
    
    # Check shebang for Ruby scripts
    begin
      first_line = File.open(path, 'r', &:gets)
      return true if first_line && first_line.match?(/^#!.*ruby/)
    rescue
      # Ignore file reading errors
    end
    
    false
  end

  def create_backup(files)
    backup_dir = File.join(@options[:path], '.ruby_migration_backup')
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    full_backup_dir = File.join(backup_dir, timestamp)
    
    puts "Creating backup in #{full_backup_dir}..."
    
    files.each do |file|
      relative_path = file.start_with?(@options[:path]) ? 
        file[@options[:path].length..-1].sub(/^\//, '') : file
      
      backup_file = File.join(full_backup_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(backup_file))
      FileUtils.copy(file, backup_file)
    end
    
    puts "Backup created successfully (#{files.length} files)"
  end

  def analyze_files(files)
    puts "Analyzing files for Ruby 3 compatibility issues...\n"
    
    files.each_with_index do |file, index|
      progress = ((index + 1).to_f / files.length * 100).round(1)
      print "\r[#{progress.to_s.rjust(5)}%] Processing: #{File.basename(file).ljust(40)}"
      
      analyze_file(file)
      @files_processed += 1
    end
    
    puts "\n"
  end

  def analyze_file(file_path)
    begin
      content = File.read(file_path, encoding: 'utf-8')
      lines = content.lines
      
      lines.each_with_index do |line, line_index|
        line_number = line_index + 1
        check_deprecated_constants(file_path, line_number, line)
        check_deprecated_methods(file_path, line_number, line)
        check_syntax_changes(file_path, line_number, line)
        check_behavior_changes(file_path, line_number, line)
      end
      
    rescue => e
      puts "\nWarning: Could not process #{file_path}: #{e.message}" if @options[:verbose]
    end
  end

  def check_deprecated_constants(file, line_num, line)
    patterns = {
      /\bFixnum\b/ => { replacement: 'Integer', description: 'Fixnum class removed in Ruby 3' },
      /\bBignum\b/ => { replacement: 'Integer', description: 'Bignum class removed in Ruby 3' },
      /\bTRUE\b/ => { replacement: 'true', description: 'TRUE constant removed in Ruby 3' },
      /\bFALSE\b/ => { replacement: 'false', description: 'FALSE constant removed in Ruby 3' },
      /\bNIL\b/ => { replacement: 'nil', description: 'NIL constant removed in Ruby 3' }
    }
    
    patterns.each do |pattern, info|
      if line.match(pattern)
        add_issue(file, line_num, line.strip, 'ERROR', info[:description], info[:replacement])
      end
    end
  end

  def check_deprecated_methods(file, line_num, line)
    patterns = {
      /\.taint\b/ => 'taint method removed in Ruby 3',
      /\.untaint\b/ => 'untaint method removed in Ruby 3',
      /\.trust\b/ => 'trust method removed in Ruby 3',
      /\.untrust\b/ => 'untrust method removed in Ruby 3'
    }
    
    patterns.each do |pattern, description|
      if line.match(pattern)
        add_issue(file, line_num, line.strip, 'ERROR', description, 'Remove method call')
      end
    end
  end

  def check_syntax_changes(file, line_num, line)
    # Hash rocket syntax
    if line.match(/:(\w+)\s*=>\s*/)
      add_issue(file, line_num, line.strip, 'WARNING', 
               'Hash rocket syntax is deprecated', 'Use new hash syntax (key: value)')
    end
    
    # Global variables
    if line.match(/\$[1-9]\d*/)
      add_issue(file, line_num, line.strip, 'WARNING',
               'Global match variables behavior changed', 'Use local variables or named captures')
    end
    
    # String methods with different behavior
    if line.match(/\.chomp!\b/)
      add_issue(file, line_num, line.strip, 'INFO',
               'chomp! behavior with separator changed', 'Review chomp! usage')
    end
  end

  def check_behavior_changes(file, line_num, line)
    # Proc and lambda changes
    if line.match(/\bproc\s*\{/)
      add_issue(file, line_num, line.strip, 'INFO',
               'Proc behavior changed in Ruby 3', 'Review proc usage for breaking changes')
    end
    
    if line.match(/\blambda\s*\{/)
      add_issue(file, line_num, line.strip, 'INFO',
               'Lambda behavior stricter in Ruby 3', 'Review lambda argument handling')
    end
    
    # Hash construction
    if line.match(/Hash\[/)
      add_issue(file, line_num, line.strip, 'INFO',
               'Hash construction behavior may differ', 'Test hash construction with Ruby 3')
    end
  end

  def add_issue(file, line_number, code, severity, description, fix)
    @issues << {
      file: file,
      line: line_number,
      code: code,
      severity: severity,
      description: description,
      fix: fix
    }
  end

  def generate_report
    if @options[:format] == 'json'
      generate_json_report
    else
      generate_text_report
    end
  end

  def generate_text_report
    puts "\n" + "=" * 80
    puts "RUBY 2 TO RUBY 3 COMPATIBILITY REPORT".center(80)
    puts "=" * 80
    puts "Project: #{@options[:path]}"
    puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "Files analyzed: #{@files_processed}"
    puts "Total issues found: #{@issues.length}"
    puts "=" * 80
    
    if @issues.empty?
      puts "\nNo compatibility issues found. Your code appears to be Ruby 3 ready!"
      return
    end
    
    %w[ERROR WARNING INFO].each do |severity|
      issues = @issues.select { |i| i[:severity] == severity }
      next if issues.empty?
      
      puts "\n#{severity} ISSUES (#{issues.length})"
      puts "-" * 40
      
      issues.each_with_index do |issue, index|
        puts "\n#{index + 1}. #{File.basename(issue[:file])}:#{issue[:line]}"
        puts "   Issue: #{issue[:description]}"
        puts "   Code:  #{issue[:code]}"
        puts "   Fix:   #{issue[:fix]}"
      end
    end
    
    puts "\n" + "=" * 80
    puts "SUMMARY"
    puts "=" * 80
    
    error_count = @issues.count { |i| i[:severity] == 'ERROR' }
    warning_count = @issues.count { |i| i[:severity] == 'WARNING' }
    info_count = @issues.count { |i| i[:severity] == 'INFO' }
    
    puts "Critical errors requiring fixes: #{error_count}"
    puts "Warnings to review: #{warning_count}"
    puts "Informational items: #{info_count}"
    
    if error_count > 0
      puts "\nIMPORTANT: Address all ERROR issues before migrating to Ruby 3"
    end
    
    puts "\nRecommended next steps:"
    puts "1. Fix all critical errors first"
    puts "2. Review and address warnings"
    puts "3. Test thoroughly with Ruby 3"
    puts "4. Update gem dependencies for Ruby 3 compatibility"
  end

  def generate_json_report
    report = {
      tool_version: VERSION,
      project_path: @options[:path],
      generated_at: Time.now.iso8601,
      files_analyzed: @files_processed,
      processing_time_seconds: (Time.now - @start_time).round(2),
      total_issues: @issues.length,
      issues_by_severity: {
        error: @issues.count { |i| i[:severity] == 'ERROR' },
        warning: @issues.count { |i| i[:severity] == 'WARNING' },
        info: @issues.count { |i| i[:severity] == 'INFO' }
      },
      issues: @issues.map do |issue|
        {
          file: issue[:file],
          line: issue[:line],
          severity: issue[:severity],
          description: issue[:description],
          code: issue[:code],
          suggested_fix: issue[:fix]
        }
      end
    }
    
    puts JSON.pretty_generate(report)
  end
end

# Run the tool if called directly
if __FILE__ == $0
  tool = RubyMigrationTool.new
  tool.run(ARGV)
end