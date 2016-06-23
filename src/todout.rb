# stub

class Todout

  def initialize
    @verbose = false
  end
  
  def verbose=(v)
    @verbose = v
  end
  
  def debug_print(msg)
    if (@verbose)
      puts msg
    end
  end

  # Gets filtered list of files that contain to-do comments in a given
  # directory.  Specific files and directories can be excluded.
  def find_files(dir, exclude_dirs = [], exclude_files = [])
    raise Exception, "Missing dir #{dir}" unless Dir.exist?(dir)

    debug_print("Searching #{dir} excluding dirs #{exclude_dirs.to_s} and files #{exclude_files.to_s}")
    
    exclude_dirs ||= []
    exclude_files ||= []
    exclude_files.map! { |e| e =~ /\.\// ? e : "./#{e}" }
    files = []
    Dir.chdir(dir) do
      debug_print("Searching #{Dir.pwd}")
      debug_print("  excluding dirs #{exclude_dirs.to_s}")
      
      files = `find . -name '*.*' -print0 | xargs -0 grep -li todo 2>/dev/null`
      files = files.split("\n")
      files = files.reject do |f|
        df = File.dirname(f)
        exclude_dirs.any? { |e| df =~ /^(\.\/)?#{e}$/ || df =~ /^(\.\/)?#{e}\// }
      end

      globbed_excluded = exclude_files.map { |f| Dir.glob(f) }.flatten
      debug_print("excluding files: #{globbed_excluded.to_s}")
      files -= globbed_excluded
    end

    if (@verbose)
      puts "Found files:\n" + files.join("\n")
    end
    
    return files
  end

  # Greps a list of files, and returns array of arrays, [[file, line], ...]
  def grepfiles(rootdir, files)
    results = []
    files.each do |f|
      fullname = File.expand_path(File.join(rootdir, f))
      result = `grep -i todo #{fullname}`.split("\n").reject { |r| r =~ /^Binary file/ }
      result.each do |r|
        results << [f, r.strip]
      end
    end
    return results
  end

  def get_grouping(line)
    tmp = line.clone
    tmp.gsub!(/^.*?todo\s*/i, '')  # ignore everything before the TODO, and the TODO
    if (tmp[0] == ":")
      return ""  # "TODO:" followed immediately by rest of line has no group
    end
    if (tmp !~ /:/)
      return ""  # if no colon, no group
    end
    tmp.gsub!(/:.*/, '')  # ignore anything after next colon
    return tmp.strip
  end

  # Searches a directory and gets TODO lines, adding grouping data.
  def get_todo_data(directory, exclude_dirs, exclude_files)
    files = find_files(directory, exclude_dirs, exclude_files)
    ret = grepfiles(directory, files).map do |file, line|
      {'file' => file, 'line' => line, 'group' => get_grouping(line) }
    end
    return ret
  end
  
end
