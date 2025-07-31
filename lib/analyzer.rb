require 'parser/current'
require_relative 'patterns'

class Analyzer
  def initialize
    @patterns = MigrationPatterns.new
    Parser::Builders::Default.emit_lambda = true
  end

  def analyze_file(file_path)
    content = File.read(file_path)
    issues = []
    
    # Text-based pattern matching for quick checks
    issues.concat(analyze_text_patterns(content, file_path))
    
    # AST-based analysis for more complex patterns
    begin
      ast = Parser::CurrentRuby.parse(content)
      issues.concat(analyze_ast(ast, file_path, content)) if ast
    rescue Parser::SyntaxError => e
      issues << {
        file: file_path,
        line: e.diagnostic.location.line,
        column: e.diagnostic.location.column,
        type: 'syntax_error',
        severity: 'error',
        message: "Syntax error: #{e.diagnostic.message}",
        suggestion: 'Fix syntax error before migration'
      }
    end
    
    issues
  end

  private

  def analyze_text_patterns(content, file_path)
    issues = []
    lines = content.split("\n")
    
    lines.each_with_index do |line, index|
      line_number = index + 1
      
      # Check for deprecated methods and patterns
      @patterns.text_patterns.each do |pattern|
        if line.match?(pattern[:regex])
          issues << {
            file: file_path,
            line: line_number,
            column: 1,
            type: pattern[:type],
            severity: pattern[:severity],
            message: pattern[:message],
            suggestion: pattern[:suggestion],
            code: line.strip
          }
        end
      end
    end
    
    issues
  end

  def analyze_ast(node, file_path, content)
    issues = []
    lines = content.split("\n")
    
    traverse_ast(node) do |n|
      case n.type
      when :send
        issues.concat(analyze_method_call(n, file_path, lines))
      when :const
        issues.concat(analyze_constant(n, file_path, lines))
      when :hash
        issues.concat(analyze_hash(n, file_path, lines))
      when :block
        issues.concat(analyze_block(n, file_path, lines))
      end
    end
    
    issues
  end

  def traverse_ast(node, &block)
    return unless node.respond_to?(:type)
    
    yield node
    
    node.children.each do |child|
      traverse_ast(child, &block) if child.respond_to?(:type)
    end
  end

  def analyze_method_call(node, file_path, lines)
    issues = []
    return issues unless node.children[1] # method name
    
    method_name = node.children[1].to_s
    line_number = node.location.line
    
    # Check for deprecated methods
    deprecated_methods = @patterns.deprecated_methods
    if deprecated_methods.key?(method_name)
      pattern = deprecated_methods[method_name]
      issues << {
        file: file_path,
        line: line_number,
        column: node.location.column,
        type: 'deprecated_method',
        severity: pattern[:severity],
        message: pattern[:message],
        suggestion: pattern[:suggestion],
        code: lines[line_number - 1]&.strip
      }
    end
    
    issues
  end

  def analyze_constant(node, file_path, lines)
    issues = []
    const_name = node.children[0].to_s
    line_number = node.location.line
    
    # Check for deprecated constants
    deprecated_constants = @patterns.deprecated_constants
    if deprecated_constants.key?(const_name)
      pattern = deprecated_constants[const_name]
      issues << {
        file: file_path,
        line: line_number,
        column: node.location.column,
        type: 'deprecated_constant',
        severity: pattern[:severity],
        message: pattern[:message],
        suggestion: pattern[:suggestion],
        code: lines[line_number - 1]&.strip
      }
    end
    
    issues
  end

  def analyze_hash(node, file_path, lines)
    issues = []
    
    # Check for hash rocket syntax in newer contexts
    node.children.each do |pair|
      next unless pair.type == :pair
      
      line_number = pair.location.line
      line_content = lines[line_number - 1]
      
      if line_content&.include?('=>') && 
         pair.children[0].type == :sym &&
         !line_content.match?(/\A\s*#/)  # Not a comment
        
        issues << {
          file: file_path,
          line: line_number,
          column: pair.location.column,
          type: 'hash_syntax',
          severity: 'warning',
          message: 'Consider using new hash syntax for symbol keys',
          suggestion: 'Replace :key => value with key: value',
          code: line_content.strip
        }
      end
    end
    
    issues
  end

  def analyze_block(node, file_path, lines)
    issues = []
    line_number = node.location.line
    line_content = lines[line_number - 1]
    
    # Check for proc usage in block context
    if line_content&.include?('proc') || line_content&.include?('Proc.new')
      issues << {
        file: file_path,
        line: line_number,
        column: node.location.column,
        type: 'proc_usage',
        severity: 'info',
        message: 'Proc behavior changed in Ruby 3',
        suggestion: 'Review proc usage for potential breaking changes',
        code: line_content.strip
      }
    end
    
    issues
  end
end
