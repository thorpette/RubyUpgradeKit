require 'find'

class FileScanner
  def initialize(base_path)
    @base_path = File.expand_path(base_path)
    @excluded_dirs = %w[.git node_modules vendor tmp log .bundle]
    @excluded_files = %w[Gemfile.lock]
  end

  def scan_ruby_files
    ruby_files = []
    
    Find.find(@base_path) do |path|
      # Skip excluded directories
      if File.directory?(path)
        dir_name = File.basename(path)
        if @excluded_dirs.include?(dir_name)
          Find.prune
          next
        end
      end
      
      # Check if it's a Ruby file
      if File.file?(path) && ruby_file?(path)
        file_name = File.basename(path)
        unless @excluded_files.include?(file_name)
          ruby_files << path
        end
      end
    end
    
    ruby_files.sort
  end

  private

  def ruby_file?(path)
    # Check file extension
    return true if path.end_with?('.rb', '.rake', '.gemspec')
    
    # Check for Ruby files without extension (like Rakefile, Gemfile)
    basename = File.basename(path)
    return true if %w[Rakefile Gemfile Capfile Guardfile Vagrantfile].include?(basename)
    
    # Check shebang for Ruby files
    if File.readable?(path)
      begin
        first_line = File.open(path, &:readline).strip
        return true if first_line.match?(/^#!.*ruby/)
      rescue EOFError, IOError
        # File is empty or unreadable
      end
    end
    
    false
  end
end
