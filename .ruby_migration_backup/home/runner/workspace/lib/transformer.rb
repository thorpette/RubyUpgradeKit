require_relative 'patterns'

class Transformer
  def initialize
    @patterns = MigrationPatterns.new
  end

  def transform_file(file_path, issues)
    content = File.read(file_path, encoding: 'UTF-8', invalid: :replace, undef: :replace)
    original_content = content.dup
    modified = false
    
    # Apply transformations based on issues found
    issues.each do |issue|
      next unless can_auto_fix?(issue)
      
      transformation = get_transformation(issue)
      next unless transformation
      
      new_content = apply_transformation(content, issue, transformation)
      if new_content != content
        content = new_content
        modified = true
      end
    end
    
    modified ? content : nil
  end

  private

  def can_auto_fix?(issue)
    auto_fixable_types = %w[
      hash_syntax
      string_concatenation
      deprecated_method_simple
      spacing_around_operators
    ]
    
    auto_fixable_types.include?(issue[:type]) && 
    issue[:severity] != 'error'
  end

  def get_transformation(issue)
    case issue[:type]
    when 'hash_syntax'
      {
        type: 'hash_syntax_modernize',
        pattern: /(\s*)(:)(\w+)(\s*)(=>)(\s*)/,
        replacement: '\1\3:\6'
      }
    when 'string_concatenation'
      {
        type: 'string_interpolation',
        pattern: /"([^"]*)" \+ ([^"\s]+) \+ "([^"]*)"/,
        replacement: '"\1#{\\2}\3"'
      }
    when 'deprecated_method_simple'
      get_method_transformation(issue)
    when 'spacing_around_operators'
      {
        type: 'operator_spacing',
        pattern: /(\S)([\+\-\*\/\=])(\S)/,
        replacement: '\1 \2 \3'
      }
    end
  end

  def get_method_transformation(issue)
    method_mappings = @patterns.method_transformations
    
    # Extract method name from the issue
    code = issue[:code]
    method_mappings.each do |old_method, new_method|
      if code.include?(old_method)
        return {
          type: 'method_replacement',
          pattern: Regexp.new("\\b#{Regexp.escape(old_method)}\\b"),
          replacement: new_method
        }
      end
    end
    
    nil
  end

  def apply_transformation(content, issue, transformation)
    lines = content.split("\n")
    line_index = issue[:line] - 1
    
    return content if line_index < 0 || line_index >= lines.length
    
    original_line = lines[line_index]
    
    case transformation[:type]
    when 'hash_syntax_modernize'
      # Transform hash rocket syntax to new syntax
      new_line = original_line.gsub(transformation[:pattern], transformation[:replacement])
      lines[line_index] = new_line
      
    when 'method_replacement'
      new_line = original_line.gsub(transformation[:pattern], transformation[:replacement])
      lines[line_index] = new_line
      
    when 'string_interpolation'
      new_line = original_line.gsub(transformation[:pattern], transformation[:replacement])
      lines[line_index] = new_line
      
    when 'operator_spacing'
      new_line = original_line.gsub(transformation[:pattern], transformation[:replacement])
      lines[line_index] = new_line
    end
    
    lines.join("\n")
  end
end