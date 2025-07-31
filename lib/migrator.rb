require_relative 'file_scanner'
require_relative 'analyzer'
require_relative 'transformer'
require_relative 'reporter'
require 'fileutils'
require 'colorize'

class Migrator
  def initialize(options = {})
    @options = options
    @scanner = FileScanner.new(options[:path])
    @analyzer = Analyzer.new
    @transformer = Transformer.new
    @reporter = Reporter.new(options[:output_format])
    @verbose = options[:verbose] || false
  end

  def analyze_only
    puts "Scanning for Ruby files..." if @verbose
    files = @scanner.scan_ruby_files
    
    puts "Found #{files.length} Ruby files".colorize(:blue)
    
    all_issues = []
    
    files.each_with_index do |file, index|
      print_progress(index + 1, files.length, file)
      
      begin
        issues = @analyzer.analyze_file(file)
        all_issues.concat(issues) if issues.any?
      rescue => e
        puts "\nError analyzing #{file}: #{e.message}".colorize(:red)
        next
      end
    end
    
    puts "\nGenerating report..."
    @reporter.generate_report(all_issues, @options[:path])
  end

  def migrate
    puts "Scanning for Ruby files..." if @verbose
    files = @scanner.scan_ruby_files
    
    puts "Found #{files.length} Ruby files".colorize(:blue)
    
    # Create backup if requested
    if @options[:backup]
      create_backup(files)
    end
    
    all_issues = []
    modified_files = []
    
    files.each_with_index do |file, index|
      print_progress(index + 1, files.length, file)
      
      begin
        issues = @analyzer.analyze_file(file)
        
        if issues.any?
          all_issues.concat(issues)
          
          # Apply transformations
          transformed_content = @transformer.transform_file(file, issues)
          
          if transformed_content
            File.write(file, transformed_content)
            modified_files << file
            puts "\n  ✓ Modified #{file}".colorize(:green) if @verbose
          end
        end
      rescue => e
        puts "\nError processing #{file}: #{e.message}".colorize(:red)
        next
      end
    end
    
    puts "\nGenerating migration report..."
    @reporter.generate_migration_report(all_issues, modified_files, @options[:path])
    
    puts "\nSummary:".colorize(:blue).bold
    puts "  Files analyzed: #{files.length}"
    puts "  Files modified: #{modified_files.length}".colorize(:green)
    puts "  Issues found: #{all_issues.length}".colorize(:yellow)
  end

  private

  def print_progress(current, total, file)
    percentage = (current.to_f / total * 100).round(1)
    file_display = file.length > 50 ? "...#{file[-47..-1]}" : file
    print "\r[#{percentage}%] Analyzing: #{file_display}"
  end

  def create_backup(files)
    backup_dir = File.join(@options[:path], '.ruby_migration_backup')
    
    puts "Creating backup in #{backup_dir}...".colorize(:yellow)
    
    files.each do |file|
      relative_path = file.sub("#{@options[:path]}/", '')
      backup_file = File.join(backup_dir, relative_path)
      backup_file_dir = File.dirname(backup_file)
      
      FileUtils.mkdir_p(backup_file_dir)
      FileUtils.cp(file, backup_file)
    end
    
    puts "Backup created successfully".colorize(:green)
  end
end
