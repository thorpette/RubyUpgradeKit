require 'json'
require 'colorize'
require 'time'

class Reporter
  def initialize(format = 'text')
    @format = format
  end

  def generate_report(issues, project_path)
    case @format
    when 'json'
      generate_json_report(issues, project_path)
    else
      generate_text_report(issues, project_path)
    end
  end

  def generate_migration_report(issues, modified_files, project_path)
    case @format
    when 'json'
      generate_json_migration_report(issues, modified_files, project_path)
    else
      generate_text_migration_report(issues, modified_files, project_path)
    end
  end

  private

  def generate_text_report(issues, project_path)
    puts "\n" + "=" * 60
    puts "Ruby 2 to Ruby 3 Compatibility Report".colorize(:blue).bold
    puts "=" * 60
    puts "Project: #{project_path}"
    puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "Total Issues: #{issues.length}\n\n"

    if issues.empty?
      puts "✓ No compatibility issues found!".colorize(:green).bold
      return
    end

    # Group issues by severity
    grouped_issues = issues.group_by { |issue| issue[:severity] }
    
    %w[error warning info].each do |severity|
      next unless grouped_issues[severity]
      
      puts "#{severity.upcase} (#{grouped_issues[severity].length})".colorize(severity_color(severity)).bold
      puts "-" * 30
      
      grouped_issues[severity].each do |issue|
        puts format_issue(issue)
        puts
      end
    end

    generate_summary(issues)
  end

  def generate_json_report(issues, project_path)
    report = {
      project_path: project_path,
      generated_at: Time.now.iso8601,
      total_issues: issues.length,
      issues_by_severity: issues.group_by { |i| i[:severity] }.transform_values(&:length),
      issues: issues
    }

    report_file = File.join(project_path, 'ruby_migration_report.json')
    File.write(report_file, JSON.pretty_generate(report))
    puts "JSON report saved to: #{report_file}".colorize(:green)
  end

  def generate_text_migration_report(issues, modified_files, project_path)
    puts "\n" + "=" * 60
    puts "Ruby Migration Completed".colorize(:green).bold
    puts "=" * 60
    puts "Project: #{project_path}"
    puts "Completed: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "Files Modified: #{modified_files.length}"
    puts "Total Issues Processed: #{issues.length}\n\n"

    if modified_files.any?
      puts "Modified Files:".colorize(:yellow).bold
      puts "-" * 20
      modified_files.each do |file|
        relative_path = file.sub("#{project_path}/", '')
        puts "  ✓ #{relative_path}".colorize(:green)
      end
      puts
    end

    # Group issues by type for summary
    issue_types = issues.group_by { |issue| issue[:type] }
    
    puts "Issues Processed by Type:".colorize(:blue).bold
    puts "-" * 30
    issue_types.each do |type, type_issues|
      count = type_issues.length
      puts "  #{type.gsub('_', ' ').capitalize}: #{count}"
    end

    puts "\nRecommendations:".colorize(:yellow).bold
    puts "-" * 20
    puts "1. Test your application thoroughly after migration"
    puts "2. Review any manual fixes needed for complex patterns"
    puts "3. Update your Gemfile to Ruby 3 compatible versions"
    puts "4. Run your test suite to ensure everything works correctly"
  end

  def generate_json_migration_report(issues, modified_files, project_path)
    report = {
      project_path: project_path,
      migration_completed_at: Time.now.iso8601,
      files_modified: modified_files.length,
      modified_files: modified_files.map { |f| f.sub("#{project_path}/", '') },
      total_issues_processed: issues.length,
      issues_by_type: issues.group_by { |i| i[:type] }.transform_values(&:length),
      issues: issues
    }

    report_file = File.join(project_path, 'ruby_migration_complete.json')
    File.write(report_file, JSON.pretty_generate(report))
    puts "Migration report saved to: #{report_file}".colorize(:green)
  end

  def format_issue(issue)
    file_path = issue[:file].split('/').last(2).join('/')
    location = "#{file_path}:#{issue[:line]}:#{issue[:column]}"
    
    output = "#{location.colorize(:cyan)} - #{issue[:message]}"
    output += "\n  Code: #{issue[:code].colorize(:light_black)}" if issue[:code]
    output += "\n  Fix: #{issue[:suggestion].colorize(:yellow)}" if issue[:suggestion]
    
    output
  end

  def severity_color(severity)
    case severity
    when 'error'
      :red
    when 'warning'
      :yellow
    when 'info'
      :blue
    else
      :white
    end
  end

  def generate_summary(issues)
    puts "Summary & Recommendations:".colorize(:blue).bold
    puts "-" * 30
    
    error_count = issues.count { |i| i[:severity] == 'error' }
    warning_count = issues.count { |i| i[:severity] == 'warning' }
    
    if error_count > 0
      puts "⚠️  #{error_count} critical issues require manual attention".colorize(:red)
    end
    
    if warning_count > 0
      puts "⚠️  #{warning_count} warnings should be reviewed".colorize(:yellow)
    end
    
    puts "\nNext Steps:"
    puts "1. Address critical errors first"
    puts "2. Review and fix warnings"
    puts "3. Test your application thoroughly"
    puts "4. Update dependencies to Ruby 3 compatible versions"
  end
end
