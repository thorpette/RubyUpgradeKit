require 'json'

class MigrationPatterns
  attr_reader :text_patterns, :deprecated_methods, :deprecated_constants, :method_transformations

  def initialize
    load_patterns
  end

  private

  def load_patterns
    @text_patterns = [
      {
        regex: /\bFixnum\b/,
        type: 'deprecated_constant',
        severity: 'error',
        message: 'Fixnum class has been removed in Ruby 3',
        suggestion: 'Replace Fixnum with Integer'
      },
      {
        regex: /\bBignum\b/,
        type: 'deprecated_constant',
        severity: 'error',
        message: 'Bignum class has been removed in Ruby 3',
        suggestion: 'Replace Bignum with Integer'
      },
      {
        regex: /\.exists\?\s*\(/,
        type: 'deprecated_method',
        severity: 'warning',
        message: 'exists? method behavior may have changed',
        suggestion: 'Review exists? usage for compatibility'
      },
      {
        regex: /\$\d+/,
        type: 'global_variable',
        severity: 'warning',
        message: 'Global match variables behavior changed',
        suggestion: 'Use local variables or named captures instead'
      },
      {
        regex: /lambda\s*\{/,
        type: 'lambda_syntax',
        severity: 'info',
        message: 'Lambda behavior is stricter in Ruby 3',
        suggestion: 'Review lambda argument handling'
      },
      {
        regex: /\.tap\s*\{.*\|\|/,
        type: 'block_parameter',
        severity: 'warning',
        message: 'Block parameter handling changed in Ruby 3',
        suggestion: 'Review block parameter usage'
      },
      {
        regex: /Hash\[[^\]]*\]/,
        type: 'hash_construction',
        severity: 'info',
        message: 'Hash construction behavior may differ',
        suggestion: 'Test hash construction with Ruby 3'
      }
    ]

    @deprecated_methods = {
      'taint' => {
        severity: 'error',
        message: 'taint method has been removed in Ruby 3',
        suggestion: 'Remove taint/untaint calls'
      },
      'untaint' => {
        severity: 'error',
        message: 'untaint method has been removed in Ruby 3',
        suggestion: 'Remove taint/untaint calls'
      },
      'trust' => {
        severity: 'error',
        message: 'trust method has been removed in Ruby 3',
        suggestion: 'Remove trust/untrust calls'
      },
      'untrust' => {
        severity: 'error',
        message: 'untrust method has been removed in Ruby 3',
        suggestion: 'Remove trust/untrust calls'
      },
      'chomp!' => {
        severity: 'warning',
        message: 'chomp! behavior with separator changed',
        suggestion: 'Review chomp! usage with separators'
      },
      'gsub!' => {
        severity: 'info',
        message: 'gsub! return value handling may need review',
        suggestion: 'Check gsub! return value handling'
      }
    }

    @deprecated_constants = {
      'Fixnum' => {
        severity: 'error',
        message: 'Fixnum constant removed in Ruby 3',
        suggestion: 'Use Integer instead of Fixnum'
      },
      'Bignum' => {
        severity: 'error',
        message: 'Bignum constant removed in Ruby 3',
        suggestion: 'Use Integer instead of Bignum'
      },
      'TimeoutError' => {
        severity: 'warning',
        message: 'TimeoutError moved to Timeout::Error',
        suggestion: 'Use Timeout::Error instead of TimeoutError'
      },
      'NIL' => {
        severity: 'error',
        message: 'NIL constant removed',
        suggestion: 'Use nil instead of NIL'
      },
      'TRUE' => {
        severity: 'error',
        message: 'TRUE constant removed',
        suggestion: 'Use true instead of TRUE'
      },
      'FALSE' => {
        severity: 'error',
        message: 'FALSE constant removed',
        suggestion: 'Use false instead of FALSE'
      }
    }

    @method_transformations = {
      'Fixnum' => 'Integer',
      'Bignum' => 'Integer',
      '.taint' => '# .taint # REMOVED',
      '.untaint' => '# .untaint # REMOVED',
      '.trust' => '# .trust # REMOVED',
      '.untrust' => '# .untrust # REMOVED',
      'NIL' => 'nil',
      'TRUE' => 'true',
      'FALSE' => 'false'
    }
  end
end
