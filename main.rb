require_relative "./src/todout"
require 'optparse'
require 'yaml'

# Program options
class MainOptionsParser

  def initialize
    @directory = ""
    @configfile = ""
    @verbose = false
    @globalconfigfile = ""
  end

  attr_accessor :directory, :configfile, :verbose, :globalconfigfile
  
  # Return a new MainOptions object describing the options.
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = MainOptionsParser.new

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename($0)} [options]"

      opts.on("-d", "--directory DIR", "Path to directory to grep") do |dir|
        options.directory = dir
      end

      opts.on("-g", "--global CONFIG", "Path to global configuration file") do |config|
        options.globalconfigfile = config
      end

      opts.on("-c", "--config CONFIG", "Path to configuration file") do |config|
        options.configfile = config
      end

      opts.on("-v", "--verbose", "Verbose output") do |v|
        options.verbose = true
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

    end

    opt_parser.parse!(args)
    options
  end


  def validate_config_file(cf)
    if (cf != "" && !File.exist?(File.expand_path(cf)))
      puts "Missing config file #{cf}"
      exit 0
    end
  end
  
  # Validate options, exit on failure.
  def validate
    if (self.directory == "")
      puts "Directory required."
      exit 0
    end

    if (!Dir.exist?(self.directory))
      puts "Missing directory #{self.directory}"
      exit 0
    end

    validate_config_file(self.configfile)
    validate_config_file(self.globalconfigfile)
  end
  
end  # class MainOptionsParser


# Writes report out to console, grouped by the groupings
def write_report(data)

  groups = data.map { |d| d['group'] }.uniq.sort
  groups.each do |g|
    curr_group_data = data.select { |d| d['group'] == g }
    
    heading = g
    heading = "<None>" if heading == ""
    puts
    puts "Group: #{heading}"

    curr_group_data.map { |d| d['file'] }.uniq.sort.each do |f|
      puts "  File: #{f}"
      curr_group_data.select { |d| d['file'] == f }.each do |d|
        puts "    #{d['line']}"
      end
    end
  end
      
end


def get_yaml_hash(filename)
  config = { "exclude_dirs" => [], "exclude_files" => [] }
  if (filename == "")
    return config
  end
  begin
    config.merge!(YAML.load_file(File.expand_path(filename)))
    return config
  rescue Psych::SyntaxError => e
    raise Exception, "Bad yaml file #{filename} (note: dir globbing must be enclosed in single quotes, eg '**/*.exe')"
  end
end


# Main entry point
def main
  begin
    options = MainOptionsParser.parse(ARGV)
    options.validate

    globalconfig = get_yaml_hash(options.globalconfigfile)
    config = get_yaml_hash(options.configfile)
    exclude_dirs = config['exclude_dirs'] + globalconfig['exclude_dirs']
    exclude_files = config['exclude_files'] + globalconfig['exclude_files']
    
    t = Todout.new()
    t.verbose = options.verbose
    d = t.get_todo_data(options.directory, exclude_dirs, exclude_files)
    write_report(d)
  rescue Exception => e
    puts e.message
  end
end


main()
