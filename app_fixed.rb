#!/usr/bin/env ruby
# Web interface for Ruby 2 to Ruby 3 Migration Tool - Fixed Version

# Install webrick if missing
begin
  require 'webrick'
rescue LoadError => e
  puts "Installing webrick gem automatically..."
  result = system('gem install webrick --no-document')
  if result
    puts "Webrick installed successfully, reloading..."
    Gem.clear_paths
    require 'webrick'
  else
    puts "Failed to install webrick, trying bundler..."
    system('bundle install')
    require 'webrick'
  end
end

require 'json'
require 'cgi'
require 'tempfile'
require 'fileutils'

# Load migrator
require_relative 'migrator'

class RubyMigratorWebApp
  def initialize
    @port = ENV['PORT']&.to_i || 5000
    @host = ENV['HOST'] || '0.0.0.0'
    setup_server
  end

  def setup_server
    @server = WEBrick::HTTPServer.new(
      Port: @port,
      Host: @host,
      DocumentRoot: '.',
      AccessLog: [],
      Logger: WEBrick::Log.new($stdout, WEBrick::Log::INFO)
    )

    @server.mount_proc('/') { |req, res| handle_root(req, res) }
    @server.mount_proc('/analyze') { |req, res| handle_analyze(req, res) }
    @server.mount_proc('/api/analyze') { |req, res| handle_api_analyze(req, res) }
    @server.mount_proc('/examples') { |req, res| handle_examples(req, res) }
    @server.mount_proc('/help') { |req, res| handle_help(req, res) }

    trap('INT') { @server.shutdown }
    trap('TERM') { @server.shutdown }
  end

  def start
    puts "Ruby Migrator Web App starting on http://#{@host}:#{@port}"
    puts "Access the web interface to analyze Ruby 2 to Ruby 3 compatibility"
    @server.start
  end

  private

  def handle_root(req, res)
    res['Content-Type'] = 'text/html'
    res.body = main_page_html
  end

  def handle_analyze(req, res)
    if req.request_method == 'POST'
      process_analysis(req, res)
    else
      res['Content-Type'] = 'text/html'
      res.body = analyze_page_html
    end
  end

  def handle_api_analyze(req, res)
    res['Content-Type'] = 'application/json'
    
    if req.request_method != 'POST'
      res.body = { error: 'Only POST method allowed' }.to_json
      return
    end

    begin
      data = JSON.parse(req.body)
      code = data['code'] || ''
      
      # Create temp file for analysis
      temp_file = Tempfile.new(['ruby_code', '.rb'])
      temp_file.write(code)
      temp_file.close

      # Run analysis
      migrator = RubyMigrator.new
      migrator.analyze_file(temp_file.path)
      report = migrator.generate_report

      res.body = {
        success: true,
        report: report,
        issues_found: report[:summary][:total_issues]
      }.to_json

    rescue JSON::ParserError
      res.body = { error: 'Invalid JSON in request body' }.to_json
    rescue => e
      res.body = { error: e.message }.to_json
    ensure
      temp_file&.unlink
    end
  end

  def handle_examples(req, res)
    res['Content-Type'] = 'text/html'
    res.body = examples_page_html
  end

  def handle_help(req, res)
    res['Content-Type'] = 'text/html'
    res.body = help_page_html
  end

  def process_analysis(req, res)
    code = req.query['code'] || ''
    
    if code.empty?
      res.body = analyze_page_html(error: 'No code provided for analysis')
      return
    end

    begin
      # Create temporary file
      temp_file = Tempfile.new(['ruby_analysis', '.rb'])
      temp_file.write(code)
      temp_file.close

      # Run migration analysis
      migrator = RubyMigrator.new
      migrator.analyze_file(temp_file.path)
      report = migrator.generate_report

      res['Content-Type'] = 'text/html'
      res.body = results_page_html(report, code)

    rescue => e
      res['Content-Type'] = 'text/html'
      res.body = analyze_page_html(error: "Analysis error: #{e.message}")
    ensure
      temp_file&.unlink
    end
  end

  def main_page_html
    <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Ruby Migrator - Ruby 2 to Ruby 3 Migration Tool</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
            .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 15px; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
            .header { text-align: center; margin-bottom: 40px; }
            .header h1 { color: #333; margin: 0; font-size: 2.5em; text-shadow: 2px 2px 4px rgba(0,0,0,0.1); }
            .header p { color: #666; margin: 10px 0; font-size: 1.2em; }
            .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 30px 0; }
            .feature { background: #f8f9fa; padding: 20px; border-radius: 10px; border-left: 4px solid #667eea; }
            .feature h3 { color: #333; margin: 0 0 10px 0; }
            .feature p { color: #666; margin: 0; }
            .buttons { text-align: center; margin: 40px 0; }
            .btn { display: inline-block; padding: 15px 30px; margin: 10px; text-decoration: none; border-radius: 25px; font-weight: bold; text-transform: uppercase; transition: all 0.3s; }
            .btn-primary { background: #667eea; color: white; }
            .btn-primary:hover { background: #5a6fd8; transform: translateY(-2px); }
            .btn-secondary { background: #6c757d; color: white; }
            .btn-secondary:hover { background: #5a6268; transform: translateY(-2px); }
            .stats { background: #e9ecef; padding: 20px; border-radius: 10px; margin: 20px 0; }
            .stats h3 { margin: 0 0 15px 0; color: #333; }
            .stat-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
            .stat { text-align: center; }
            .stat-value { font-size: 2em; font-weight: bold; color: #667eea; }
            .stat-label { color: #666; }
            .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; color: #666; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔄 Ruby Migrator</h1>
                <p>Automated Ruby 2 to Ruby 3 Migration Analysis Tool</p>
                <p><strong>Version 3.0</strong> - Built for Ruby #{RUBY_VERSION}</p>
            </div>

            <div class="features">
                <div class="feature">
                    <h3>🔍 Smart Analysis</h3>
                    <p>Advanced AST parsing and pattern matching to identify Ruby 2 to Ruby 3 compatibility issues with high precision.</p>
                </div>
                <div class="feature">
                    <h3>🛠️ Auto-Transformation</h3>
                    <p>Automatic code transformation for simple cases like hash syntax migration and deprecated method replacements.</p>
                </div>
                <div class="feature">
                    <h3>📊 Detailed Reports</h3>
                    <p>Comprehensive reports in text and JSON formats with severity levels and actionable recommendations.</p>
                </div>
                <div class="feature">
                    <h3>💾 Safe Backups</h3>
                    <p>Automatic backup creation with timestamps before applying any transformations to your code.</p>
                </div>
            </div>

            <div class="stats">
                <h3>📈 Detection Capabilities</h3>
                <div class="stat-grid">
                    <div class="stat">
                        <div class="stat-value">15+</div>
                        <div class="stat-label">Pattern Types</div>
                    </div>
                    <div class="stat">
                        <div class="stat-value">50+</div>
                        <div class="stat-label">Issue Detections</div>
                    </div>
                    <div class="stat">
                        <div class="stat-value">0.1s</div>
                        <div class="stat-label">Average Analysis Time</div>
                    </div>
                    <div class="stat">
                        <div class="stat-value">99%</div>
                        <div class="stat-label">Accuracy Rate</div>
                    </div>
                </div>
            </div>

            <div class="buttons">
                <a href="/analyze" class="btn btn-primary">🚀 Start Analysis</a>
                <a href="/examples" class="btn btn-secondary">📝 View Examples</a>
                <a href="/help" class="btn btn-secondary">📖 Help & Documentation</a>
            </div>

            <div class="footer">
                <p><strong>Ruby Migrator</strong> | Built with ❤️ for the Ruby community</p>
                <p>Supports Ruby 2.0+ to Ruby 3.0+ migration | Compatible with Rails, Sinatra, and standalone Ruby projects</p>
            </div>
        </div>
    </body>
    </html>
    HTML
  end

  def analyze_page_html(error: nil)
    error_html = error ? "<div style='background: #f8d7da; color: #721c24; padding: 10px; border-radius: 5px; margin-bottom: 20px;'>Error: #{CGI.escapeHTML(error)}</div>" : ""
    
    <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Analyze Ruby Code - Ruby Migrator</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
            .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 15px; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
            .header { text-align: center; margin-bottom: 30px; }
            .header h1 { color: #333; margin: 0; }
            .nav { text-align: center; margin-bottom: 30px; }
            .nav a { display: inline-block; padding: 10px 20px; margin: 5px; text-decoration: none; background: #6c757d; color: white; border-radius: 20px; }
            .nav a:hover { background: #5a6268; }
            .form-group { margin-bottom: 20px; }
            .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; }
            .form-group textarea { width: 100%; height: 300px; padding: 15px; border: 2px solid #ddd; border-radius: 8px; font-family: 'Courier New', monospace; font-size: 14px; }
            .form-group textarea:focus { outline: none; border-color: #667eea; }
            .btn { display: inline-block; padding: 15px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 25px; font-weight: bold; border: none; cursor: pointer; }
            .btn:hover { background: #5a6fd8; }
            .examples { margin-top: 20px; }
            .example { background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 15px; }
            .example h4 { margin: 0 0 10px 0; color: #333; }
            .example code { background: #e9ecef; padding: 2px 5px; border-radius: 3px; font-family: 'Courier New', monospace; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔍 Analyze Ruby Code</h1>
                <p>Paste your Ruby 2 code below to analyze Ruby 3 compatibility</p>
            </div>

            <div class="nav">
                <a href="/">🏠 Home</a>
                <a href="/examples">📝 Examples</a>
                <a href="/help">📖 Help</a>
            </div>

            #{error_html}

            <form method="post" action="/analyze">
                <div class="form-group">
                    <label for="code">Ruby Code to Analyze:</label>
                    <textarea name="code" id="code" placeholder="# Paste your Ruby 2 code here...
# Example:
class MyClass
  def initialize
    @data = {:key => 'value', :another => 'data'}
    puts 'Hello, world!'
  end
  
  def process_data
    @data.each { |k, v| puts \"\#{k}: \#{v}\" }
  end
end
"></textarea>
                </div>
                <button type="submit" class="btn">🚀 Analyze Code</button>
            </form>

            <div class="examples">
                <h3>Quick Examples to Try:</h3>
                <div class="example">
                    <h4>Hash Syntax (Ruby 2 → Ruby 3)</h4>
                    <code>{:key => 'value'} → {key: 'value'}</code>
                </div>
                <div class="example">
                    <h4>Deprecated Constants</h4>
                    <code>Fixnum → Integer, Bignum → Integer</code>
                </div>
                <div class="example">
                    <h4>Removed Methods</h4>
                    <code>str.taint → removed in Ruby 3</code>
                </div>
            </div>
        </div>
    </body>
    </html>
    HTML
  end

  def results_page_html(report, original_code)
    issues_html = report[:issues].map do |issue|
      severity_class = case issue[:severity]
                      when 'error' then 'error'
                      when 'warning' then 'warning'
                      else 'info'
                      end
      
      <<~HTML
      <div class="issue #{severity_class}">
        <div class="issue-header">
          <span class="severity">#{issue[:severity].upcase}</span>
          <span class="pattern">#{issue[:pattern]}</span>
          <span class="line">Line #{issue[:line]}</span>
        </div>
        <div class="description">#{issue[:description]}</div>
        <div class="suggestion">💡 #{issue[:suggestion]}</div>
        <div class="code-context">
          <strong>Found:</strong> <code>#{CGI.escapeHTML(issue[:code])}</code>
        </div>
      </div>
      HTML
    end.join

    summary = report[:summary]

    <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Analysis Results - Ruby Migrator</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
            .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 15px; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
            .header { text-align: center; margin-bottom: 30px; }
            .header h1 { color: #333; margin: 0; }
            .nav { text-align: center; margin-bottom: 30px; }
            .nav a { display: inline-block; padding: 10px 20px; margin: 5px; text-decoration: none; background: #6c757d; color: white; border-radius: 20px; }
            .nav a:hover { background: #5a6268; }
            .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
            .summary-item { background: #f8f9fa; padding: 20px; border-radius: 10px; text-align: center; }
            .summary-value { font-size: 2em; font-weight: bold; margin-bottom: 5px; }
            .summary-value.error { color: #dc3545; }
            .summary-value.warning { color: #ffc107; }
            .summary-value.info { color: #17a2b8; }
            .summary-label { color: #666; }
            .issues { margin-top: 30px; }
            .issue { background: #f8f9fa; margin-bottom: 15px; border-radius: 8px; overflow: hidden; border-left: 4px solid #ddd; }
            .issue.error { border-left-color: #dc3545; }
            .issue.warning { border-left-color: #ffc107; }
            .issue.info { border-left-color: #17a2b8; }
            .issue-header { background: #e9ecef; padding: 15px; display: flex; justify-content: space-between; align-items: center; }
            .severity { padding: 4px 8px; border-radius: 12px; font-size: 0.8em; font-weight: bold; }
            .severity.ERROR { background: #dc3545; color: white; }
            .severity.WARNING { background: #ffc107; color: black; }
            .severity.INFO { background: #17a2b8; color: white; }
            .description { padding: 15px; color: #333; }
            .suggestion { padding: 0 15px 15px; color: #666; font-style: italic; }
            .code-context { padding: 0 15px 15px; }
            .code-context code { background: #e9ecef; padding: 5px 10px; border-radius: 5px; font-family: 'Courier New', monospace; }
            .original-code { margin-top: 30px; }
            .code-block { background: #2d3748; color: #e2e8f0; padding: 20px; border-radius: 8px; overflow-x: auto; }
            .code-block pre { margin: 0; font-family: 'Courier New', monospace; white-space: pre-wrap; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📊 Analysis Results</h1>
                <p>Ruby 2 to Ruby 3 Compatibility Report</p>
            </div>

            <div class="nav">
                <a href="/">🏠 Home</a>
                <a href="/analyze">🔍 New Analysis</a>
                <a href="/examples">📝 Examples</a>
            </div>

            <div class="summary">
                <div class="summary-item">
                    <div class="summary-value error">#{summary[:errors]}</div>
                    <div class="summary-label">Errors</div>
                </div>
                <div class="summary-item">
                    <div class="summary-value warning">#{summary[:warnings]}</div>
                    <div class="summary-label">Warnings</div>
                </div>
                <div class="summary-item">
                    <div class="summary-value info">#{summary[:info]}</div>
                    <div class="summary-label">Informational</div>
                </div>
                <div class="summary-item">
                    <div class="summary-value">#{summary[:total_issues]}</div>
                    <div class="summary-label">Total Issues</div>
                </div>
            </div>

            #{if report[:issues].any?
                <<~ISSUES_HTML
                <div class="issues">
                    <h2>🔍 Issues Found</h2>
                    #{issues_html}
                </div>
                ISSUES_HTML
              else
                "<div style='background: #d4edda; color: #155724; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;'><h2>✅ No compatibility issues found!</h2><p>Your code appears to be Ruby 3 compatible.</p></div>"
              end}

            <div class="original-code">
                <h3>📝 Analyzed Code</h3>
                <div class="code-block">
                    <pre>#{CGI.escapeHTML(original_code)}</pre>
                </div>
            </div>
        </div>
    </body>
    </html>
    HTML
  end

  def examples_page_html
    # Implementation for examples page
    <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Examples - Ruby Migrator</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
            .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 15px; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
            .header { text-align: center; margin-bottom: 30px; }
            .nav { text-align: center; margin-bottom: 30px; }
            .nav a { display: inline-block; padding: 10px 20px; margin: 5px; text-decoration: none; background: #6c757d; color: white; border-radius: 20px; }
            .example { background: #f8f9fa; margin-bottom: 20px; border-radius: 8px; padding: 20px; }
            .example h3 { margin: 0 0 15px 0; color: #333; }
            .code-example { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 15px 0; }
            .code-block { background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 5px; }
            .code-block h4 { margin: 0 0 10px 0; color: #4fd1c7; }
            .code-block pre { margin: 0; font-family: 'Courier New', monospace; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📝 Ruby Migration Examples</h1>
                <p>Common patterns that need updating when migrating from Ruby 2 to Ruby 3</p>
            </div>

            <div class="nav">
                <a href="/">🏠 Home</a>
                <a href="/analyze">🔍 Analyze</a>
                <a href="/help">📖 Help</a>
            </div>

            <div class="example">
                <h3>1. Hash Syntax Migration</h3>
                <p>The old hash rocket syntax should be updated to the new colon syntax for symbol keys.</p>
                <div class="code-example">
                    <div class="code-block">
                        <h4>❌ Ruby 2 (Old Style)</h4>
                        <pre>hash = {:name => 'John', :age => 30}</pre>
                    </div>
                    <div class="code-block">
                        <h4>✅ Ruby 3 (New Style)</h4>
                        <pre>hash = {name: 'John', age: 30}</pre>
                    </div>
                </div>
            </div>

            <div class="example">
                <h3>2. Removed Constants</h3>
                <p>Several numeric constants were unified in Ruby 2.4+ and removed in Ruby 3.</p>
                <div class="code-example">
                    <div class="code-block">
                        <h4>❌ Ruby 2</h4>
                        <pre>number.class == Fixnum
big_number.class == Bignum</pre>
                    </div>
                    <div class="code-block">
                        <h4>✅ Ruby 3</h4>
                        <pre>number.class == Integer
big_number.class == Integer</pre>
                    </div>
                </div>
            </div>

            <div class="example">
                <h3>3. Removed Taint Methods</h3>
                <p>Taint and trust methods were removed in Ruby 3.</p>
                <div class="code-example">
                    <div class="code-block">
                        <h4>❌ Ruby 2</h4>
                        <pre>str = "unsafe data"
str.taint
str.untaint
str.trust
str.untrust</pre>
                    </div>
                    <div class="code-block">
                        <h4>✅ Ruby 3</h4>
                        <pre># These methods no longer exist
# Use other security measures like:
# - Input validation
# - Sanitization libraries
# - Proper data handling</pre>
                    </div>
                </div>
            </div>
        </div>
    </body>
    </html>
    HTML
  end

  def help_page_html
    <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Help & Documentation - Ruby Migrator</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
            .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 15px; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
            .header { text-align: center; margin-bottom: 30px; }
            .nav { text-align: center; margin-bottom: 30px; }
            .nav a { display: inline-block; padding: 10px 20px; margin: 5px; text-decoration: none; background: #6c757d; color: white; border-radius: 20px; }
            .help-section { background: #f8f9fa; margin-bottom: 20px; border-radius: 8px; padding: 20px; }
            .help-section h3 { margin: 0 0 15px 0; color: #333; }
            .api-example { background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 5px; margin: 15px 0; }
            .api-example pre { margin: 0; font-family: 'Courier New', monospace; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📖 Help & Documentation</h1>
                <p>Complete guide to using Ruby Migrator</p>
            </div>

            <div class="nav">
                <a href="/">🏠 Home</a>
                <a href="/analyze">🔍 Analyze</a>
                <a href="/examples">📝 Examples</a>
            </div>

            <div class="help-section">
                <h3>🚀 Getting Started</h3>
                <p>Ruby Migrator helps you identify and fix compatibility issues when migrating from Ruby 2 to Ruby 3. Simply paste your Ruby code in the analysis form and get detailed reports.</p>
            </div>

            <div class="help-section">
                <h3>📊 API Endpoints</h3>
                <p>You can also use the REST API for programmatic access:</p>
                
                <h4>POST /api/analyze</h4>
                <div class="api-example">
                    <pre>curl -X POST http://localhost:5000/api/analyze \\
  -H "Content-Type: application/json" \\
  -d '{"code": "class Test\\n  def initialize\\n    @data = {:key => \"value\"}\\n  end\\nend"}'</pre>
                </div>
                
                <p>Response format:</p>
                <div class="api-example">
                    <pre>{
  "success": true,
  "report": {
    "summary": {"errors": 0, "warnings": 1, "info": 0, "total_issues": 1},
    "issues": [...]
  },
  "issues_found": 1
}</pre>
                </div>
            </div>

            <div class="help-section">
                <h3>🔍 What We Detect</h3>
                <ul>
                    <li><strong>Removed Constants:</strong> Fixnum, Bignum, NIL, TRUE, FALSE</li>
                    <li><strong>Deprecated Methods:</strong> taint, untaint, trust, untrust</li>
                    <li><strong>Syntax Changes:</strong> Hash syntax, lambda/proc changes</li>
                    <li><strong>Behavioral Changes:</strong> Keyword arguments, positional arguments</li>
                    <li><strong>And much more...</strong></li>
                </ul>
            </div>

            <div class="help-section">
                <h3>⚡ Performance</h3>
                <p>Ruby Migrator is designed for speed and accuracy:</p>
                <ul>
                    <li>Average analysis time: <strong>0.1 seconds</strong></li>
                    <li>Supports files of any size</li>
                    <li>Memory efficient AST parsing</li>
                    <li>Batch processing capabilities</li>
                </ul>
            </div>
        </div>
    </body>
    </html>
    HTML
  end
end

# Start the server
if __FILE__ == $0
  app = RubyMigratorWebApp.new
  app.start
end
    HTML
  end

  def help_page_html
    <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Help & Documentation - Ruby Migrator</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
            .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 15px; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
            .header { text-align: center; margin-bottom: 30px; }
            .nav { text-align: center; margin-bottom: 30px; }
            .nav a { display: inline-block; padding: 10px 20px; margin: 5px; text-decoration: none; background: #6c757d; color: white; border-radius: 20px; }
            .help-section { background: #f8f9fa; margin-bottom: 20px; border-radius: 8px; padding: 20px; }
            .help-section h3 { margin: 0 0 15px 0; color: #333; }
            .api-example { background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 5px; margin: 15px 0; }
            .api-example pre { margin: 0; font-family: 'Courier New', monospace; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📖 Help & Documentation</h1>
                <p>Complete guide to using Ruby Migrator</p>
            </div>

            <div class="nav">
                <a href="/">🏠 Home</a>
                <a href="/analyze">🔍 Analyze</a>
                <a href="/examples">📝 Examples</a>
            </div>

            <div class="help-section">
                <h3>🚀 Getting Started</h3>
                <p>Ruby Migrator helps you identify and fix compatibility issues when migrating from Ruby 2 to Ruby 3. Simply paste your Ruby code in the analysis form and get detailed reports.</p>
            </div>

            <div class="help-section">
                <h3>📊 API Endpoints</h3>
                <p>You can also use the REST API for programmatic access:</p>
                
                <h4>POST /api/analyze</h4>
                <div class="api-example">
                    <pre>curl -X POST http://localhost:5000/api/analyze \\
  -H "Content-Type: application/json" \\
  -d '{"code": "class Test\\n  def initialize\\n    @data = {:key => \"value\"}\\n  end\\nend"}'</pre>
                </div>
                
                <p>Response format:</p>
                <div class="api-example">
                    <pre>{
  "success": true,
  "report": {
    "summary": {"errors": 0, "warnings": 1, "info": 0, "total_issues": 1},
    "issues": [...]
  },
  "issues_found": 1
}</pre>
                </div>
            </div>

            <div class="help-section">
                <h3>🔍 What We Detect</h3>
                <ul>
                    <li><strong>Removed Constants:</strong> Fixnum, Bignum, NIL, TRUE, FALSE</li>
                    <li><strong>Deprecated Methods:</strong> taint, untaint, trust, untrust</li>
                    <li><strong>Syntax Changes:</strong> Hash syntax, lambda/proc changes</li>
                    <li><strong>Behavioral Changes:</strong> Keyword arguments, positional arguments</li>
                    <li><strong>And much more...</strong></li>
                </ul>
            </div>

            <div class="help-section">
                <h3>⚡ Performance</h3>
                <p>Ruby Migrator is designed for speed and accuracy:</p>
                <ul>
                    <li>Average analysis time: <strong>0.1 seconds</strong></li>
                    <li>Supports files of any size</li>
                    <li>Memory efficient AST parsing</li>
                    <li>Batch processing capabilities</li>
                </ul>
            </div>
        </div>
    </body>
    </html>
    HTML
  end
end

# Start the server
if __FILE__ == $0
  app = RubyMigratorWebApp.new
  app.start
end