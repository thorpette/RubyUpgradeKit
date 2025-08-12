#!/usr/bin/env ruby
# Web interface for Ruby 2 to Ruby 3 Migration Tool

require 'webrick'
require 'json'
require 'cgi'
require 'tempfile'
require 'fileutils'

class RubyMigratorWebApp
  def initialize
    @port = ENV['PORT'] || 5000
    @host = ENV['HOST'] || '0.0.0.0'
    @instance_name = ENV['INSTANCE_NAME'] || 'Ruby Migrator'
    
    @server = WEBrick::HTTPServer.new(
      Port: @port.to_i,
      Host: @host,
      DocumentRoot: '.'
    )
    
    setup_routes
    
    # Handle shutdown gracefully
    trap('INT') { @server.shutdown }
  end

  def start
    puts "#{@instance_name} Web App starting on http://#{@host}:#{@port}"
    puts "Access the web interface to analyze Ruby 2 to Ruby 3 compatibility"
    @server.start
  end

  private

  def setup_routes
    @server.mount_proc '/' do |req, res|
      serve_home_page(req, res)
    end

    @server.mount_proc '/analyze' do |req, res|
      handle_analysis(req, res)
    end

    @server.mount_proc '/api/analyze' do |req, res|
      handle_api_analysis(req, res)
    end
  end

  def serve_home_page(req, res)
    res.content_type = 'text/html'
    res.body = generate_html_interface
  end

  def handle_analysis(req, res)
    if req.request_method == 'POST'
      code = req.query['code'] || ''
      format = req.query['format'] || 'text'
      
      result = analyze_ruby_code(code, format)
      
      res.content_type = format == 'json' ? 'application/json' : 'text/plain'
      res.body = result
    else
      res.status = 405
      res.body = 'Method not allowed'
    end
  end

  def handle_api_analysis(req, res)
    res['Access-Control-Allow-Origin'] = '*'
    res['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    res['Access-Control-Allow-Headers'] = 'Content-Type'
    
    if req.request_method == 'OPTIONS'
      res.status = 200
      return
    end
    
    if req.request_method == 'POST'
      begin
        body = req.body
        data = JSON.parse(body)
        code = data['code'] || ''
        format = data['format'] || 'json'
        
        result = analyze_ruby_code(code, format)
        
        res.content_type = 'application/json'
        res.body = format == 'json' ? result : { result: result }.to_json
      rescue JSON::ParserError
        res.status = 400
        res.content_type = 'application/json'
        res.body = { error: 'Invalid JSON' }.to_json
      rescue => e
        res.status = 500
        res.content_type = 'application/json'
        res.body = { error: e.message }.to_json
      end
    else
      res.status = 405
      res.content_type = 'application/json'
      res.body = { error: 'Method not allowed' }.to_json
    end
  end

  def analyze_ruby_code(code, format = 'text')
    return { error: 'No code provided' }.to_json if code.empty?
    
    # Create temporary file with the Ruby code
    temp_file = Tempfile.new(['ruby_code', '.rb'])
    begin
      temp_file.write(code)
      temp_file.close
      
      # Run the migrator on the temporary file
      cmd = "ruby migrator.rb -p #{temp_file.path} -r"
      cmd += " -f json" if format == 'json'
      
      result = `#{cmd} 2>&1`
      
      # Clean up the output for web display
      if format == 'json'
        # Extract JSON from the output
        json_start = result.index('{')
        if json_start
          json_part = result[json_start..-1]
          # Find the end of JSON
          json_end = json_part.rindex('}')
          if json_end
            json_part = json_part[0..json_end]
            return json_part
          end
        end
        return { error: 'Could not parse analysis result' }.to_json
      else
        return result
      end
      
    ensure
      temp_file.unlink
    end
  end

  def generate_html_interface
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Ruby 2 to Ruby 3 Migration Tool</title>
          <style>
              * {
                  box-sizing: border-box;
                  margin: 0;
                  padding: 0;
              }
              
              body {
                  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  min-height: 100vh;
                  padding: 20px;
              }
              
              .container {
                  max-width: 1200px;
                  margin: 0 auto;
                  background: white;
                  border-radius: 10px;
                  box-shadow: 0 10px 30px rgba(0,0,0,0.2);
                  overflow: hidden;
              }
              
              .header {
                  background: #2c3e50;
                  color: white;
                  padding: 30px;
                  text-align: center;
              }
              
              .header h1 {
                  font-size: 2.5em;
                  margin-bottom: 10px;
              }
              
              .header p {
                  font-size: 1.1em;
                  opacity: 0.9;
              }
              
              .content {
                  padding: 30px;
              }
              
              .input-section {
                  margin-bottom: 30px;
              }
              
              .input-section h2 {
                  color: #2c3e50;
                  margin-bottom: 15px;
                  font-size: 1.5em;
              }
              
              #codeInput {
                  width: 100%;
                  height: 300px;
                  padding: 15px;
                  border: 2px solid #ddd;
                  border-radius: 5px;
                  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
                  font-size: 14px;
                  resize: vertical;
                  background: #f8f9fa;
              }
              
              .controls {
                  display: flex;
                  gap: 15px;
                  margin: 20px 0;
                  align-items: center;
              }
              
              .btn-primary {
                  background: #3498db;
                  color: white;
                  border: none;
                  padding: 12px 24px;
                  border-radius: 5px;
                  cursor: pointer;
                  font-size: 16px;
                  transition: background 0.3s;
              }
              
              .btn-primary:hover {
                  background: #2980b9;
              }
              
              .btn-secondary {
                  background: #95a5a6;
                  color: white;
                  border: none;
                  padding: 12px 24px;
                  border-radius: 5px;
                  cursor: pointer;
                  font-size: 16px;
                  transition: background 0.3s;
              }
              
              .btn-secondary:hover {
                  background: #7f8c8d;
              }
              
              select {
                  padding: 8px 12px;
                  border: 2px solid #ddd;
                  border-radius: 5px;
                  font-size: 14px;
              }
              
              .result-section {
                  margin-top: 30px;
              }
              
              #result {
                  background: #f8f9fa;
                  border: 2px solid #ddd;
                  border-radius: 5px;
                  padding: 20px;
                  min-height: 200px;
                  white-space: pre-wrap;
                  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
                  font-size: 13px;
                  line-height: 1.5;
                  overflow-x: auto;
              }
              
              .loading {
                  text-align: center;
                  color: #666;
                  font-style: italic;
              }
              
              .error {
                  color: #e74c3c;
                  background: #fdf2f2;
                  border-left: 4px solid #e74c3c;
                  padding: 15px;
                  margin: 15px 0;
              }
              
              .success {
                  color: #27ae60;
                  background: #f2fdf5;
                  border-left: 4px solid #27ae60;
                  padding: 15px;
                  margin: 15px 0;
              }
              
              .examples {
                  background: #ecf0f1;
                  padding: 20px;
                  border-radius: 5px;
                  margin: 20px 0;
              }
              
              .examples h3 {
                  color: #2c3e50;
                  margin-bottom: 10px;
              }
              
              .example-code {
                  background: #34495e;
                  color: #ecf0f1;
                  padding: 10px;
                  border-radius: 3px;
                  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
                  font-size: 12px;
                  margin: 10px 0;
                  cursor: pointer;
                  transition: background 0.3s;
              }
              
              .example-code:hover {
                  background: #2c3e50;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="header">
                  <h1>Ruby Migration Tool</h1>
                  <p>Analyze Ruby 2 code for Ruby 3 compatibility issues</p>
              </div>
              
              <div class="content">
                  <div class="input-section">
                      <h2>Enter Ruby Code to Analyze</h2>
                      <textarea id="codeInput" placeholder="Paste your Ruby 2 code here..."></textarea>
                      
                      <div class="controls">
                          <button class="btn-primary" onclick="analyzeCode()">Analyze Code</button>
                          <button class="btn-secondary" onclick="clearAll()">Clear</button>
                          <select id="formatSelect">
                              <option value="text">Text Report</option>
                              <option value="json">JSON Report</option>
                          </select>
                      </div>
                  </div>
                  
                  <div class="examples">
                      <h3>Ruby 2 Code Examples (Click to load)</h3>
                      <div class="example-code" onclick="loadExample1()">
class LegacyClass
  def check_number(num)
    if num.is_a?(Fixnum)
      return TRUE
    elsif num.is_a?(Bignum)
      return FALSE
    end
    return NIL
  end
end
                      </div>
                      <div class="example-code" onclick="loadExample2()">
def process_data(input)
  input.taint
  cleaned = sanitize(input)
  cleaned.untaint
  input.trust
  return cleaned
end

def parse_url(url)
  if url =~ /https?:\/\/(\w+):(\d+)/
    host = $1
    port = $2.to_i
    return { host: host, port: port }
  end
end
                      </div>
                      <div class="example-code" onclick="loadFixedExample()">
# Ruby 3 Compatible (Fixed Version)
class ModernClass
  def check_number(num)
    if num.is_a?(Integer)
      return true
    else
      return false
    end
  end
end

def process_data(input)
  cleaned = sanitize(input)
  return cleaned
end

def parse_url(url)
  if match = url.match(/https?:\/\/(?<host>\w+):(?<port>\d+)/)
    host = match[:host]
    port = match[:port].to_i
    return { host: host, port: port }
  end
end
                      </div>
                  </div>
                  
                  <div class="result-section">
                      <h2>Analysis Result</h2>
                      <div id="result">Click "Analyze Code" to see compatibility issues...</div>
                  </div>
              </div>
          </div>
          
          <script>
              function analyzeCode() {
                  const code = document.getElementById('codeInput').value.trim();
                  const format = document.getElementById('formatSelect').value;
                  const resultDiv = document.getElementById('result');
                  
                  if (!code) {
                      resultDiv.innerHTML = '<div class="error">Please enter some Ruby code to analyze.</div>';
                      return;
                  }
                  
                  resultDiv.innerHTML = '<div class="loading">Analyzing code...</div>';
                  
                  fetch('/api/analyze', {
                      method: 'POST',
                      headers: {
                          'Content-Type': 'application/json',
                      },
                      body: JSON.stringify({
                          code: code,
                          format: format
                      })
                  })
                  .then(response => response.json())
                  .then(data => {
                      if (data.error) {
                          resultDiv.innerHTML = `<div class="error">Error: ${data.error}</div>`;
                      } else {
                          if (format === 'json') {
                              resultDiv.innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                          } else {
                              resultDiv.innerHTML = '<pre>' + (data.result || data) + '</pre>';
                          }
                      }
                  })
                  .catch(error => {
                      resultDiv.innerHTML = `<div class="error">Network error: ${error.message}</div>`;
                  });
              }
              
              function clearAll() {
                  document.getElementById('codeInput').value = '';
                  document.getElementById('result').innerHTML = 'Click "Analyze Code" to see compatibility issues...';
              }
              
              function loadExample1() {
                  document.getElementById('codeInput').value = `class LegacyClass
  def check_number(num)
    if num.is_a?(Fixnum)
      return TRUE
    elsif num.is_a?(Bignum)
      return FALSE
    end
    return NIL
  end
end`;
              }
              
              function loadExample2() {
                  document.getElementById('codeInput').value = `def process_data(input)
  input.taint
  cleaned = sanitize(input)
  cleaned.untaint
  input.trust
  return cleaned
end

def parse_url(url)
  if url =~ /https?:\\/\\/(\\w+):(\\d+)/
    host = $1
    port = $2.to_i
    return { host: host, port: port }
  end
end`;
              }
              
              function loadFixedExample() {
                  document.getElementById('codeInput').value = `# Ruby 3 Compatible (Fixed Version)
class ModernClass
  def check_number(num)
    if num.is_a?(Integer)
      return true
    else
      return false
    end
  end
end

def process_data(input)
  cleaned = sanitize(input)
  return cleaned
end

def parse_url(url)
  if match = url.match(/https?:\\/\\/(?<host>\\w+):(?<port>\\d+)/)
    host = match[:host]
    port = match[:port].to_i
    return { host: host, port: port }
  end
end`;
              }
          </script>
      </body>
      </html>
    HTML
  end
end

# Start the web application
if __FILE__ == $0
  app = RubyMigratorWebApp.new
  app.start
end