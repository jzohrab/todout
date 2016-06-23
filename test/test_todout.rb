 
require_relative "../src/todout"
require "test/unit"
 
class TestTodout < Test::Unit::TestCase

  def setup
    @todout = Todout.new
    @sampleproj_todofiles = %w(./a.txt
./ignoreMe/ignoreA.txt
./subA/ignoreMeSubA/subAignore.txt
./subA/subAfile.txt)
  end

  def test_happy_path
    files = @todout.find_files("sampleproj")
    assert_equal(files.sort, @sampleproj_todofiles.sort, "Found files")
  end
  
  def test_directory_must_exist
    assert_raises(Exception) { @todout.find_files("missing_dir") }
  end

  def assert_found_files_with_config_equals(excl_dirs, excl_files, expected_excluded, msg = "found files")
    files = @todout.find_files("sampleproj", excl_dirs, excl_files)
    expected_files = @sampleproj_todofiles - expected_excluded
    assert_equal(expected_files, files.sort, msg)
  end
  
  def test_can_exclude_specific_directories
    excl = ["./ignoreMe/ignoreA.txt"]
    assert_found_files_with_config_equals(["ignoreMe"], [], excl)
  end

  def test_excluded_dir_can_start_with_dot_slash
    excl = ["./ignoreMe/ignoreA.txt"]
    assert_found_files_with_config_equals(["./ignoreMe"], [], excl)
  end

  def test_can_exclude_non_existent_dir
    excl = []
    assert_found_files_with_config_equals(["garbageDir"], [], excl)
  end

  def test_can_exclude_specific_file_with_optional_dot_slash
    excl = ["./ignoreMe/ignoreA.txt"]
    assert_found_files_with_config_equals([], ["./ignoreMe/ignoreA.txt"], excl, "dotslash included")
    assert_found_files_with_config_equals([], ["ignoreMe/ignoreA.txt"], excl, "Missing dotslash is OK")
  end

  def test_ignoring_subdir_also_ignores_nested_dirs
    excl = [ "./subA/ignoreMeSubA/subAignore.txt", "./subA/subAfile.txt" ]
    assert_found_files_with_config_equals(["./subA"], [], excl, "nested dir ignored")
  end

  def test_ignore_partname_of_subdir_only_does_not_accidentally_ignore_subdir
    # test dir is "subA", so ignoring "sub" should *not* ignore "subA", as that name doesn't match
    excl = []
    assert_found_files_with_config_equals(["./sub"], [], excl, "all files returned")
  end
                    
  def test_can_exclude_globbed_file
    assert_found_files_with_config_equals([], ["**/*.txt"], @sampleproj_todofiles, "all files excluded!")

    excl = ["./ignoreMe/ignoreA.txt"]
    assert_found_files_with_config_equals([], ["**/ignore*.txt"], excl, "globbed match")
  end
  

  def test_individual_files_are_grepped_for_todo
    files = ["./a.txt"]
    results = @todout.grepfiles("sampleproj", files)
    expected = [
      ["./a.txt", "TODO groupA: something"],
      ["./a.txt", "TODO group B: another thing"]
    ]
    assert_equal(expected, results)
  end

  def assert_parsed_todo_grouping_equals(line, expected_grouping)
    g = @todout.get_grouping(line)
    assert_equal(expected_grouping, g, line)
  end
  
  def test_TODO_comments_can_be_parsed
    [
      [ "TODO groupA: rest of line is ignored", "groupA" ],
      [ "# TODO some group: all words after to-do up to the colon form the group", "some group" ],
      [ "# TODO some group    : spaces stripped", "some group" ],
      [ "# TODO some group    :", "some group" ],
      [ "# TODO some group: can have a TODO in middle: but the first to-do determines the group", "some group" ],
      [ "# TODO another: next semicolon: is ignored", "another" ],
      [ "# a line with: some stuff todo grouping: todo in middle of sentence is used", "grouping" ],
      [ "TODO: followed directly by colon = no group", "" ],
      [ "TODO with no colon = no group", "" ],
      [ "# this todo case-insensitive: case doesn't matter", "case-insensitive" ]
    ].each do |line, expected_group|
      assert_parsed_todo_grouping_equals(line, expected_group)
    end
  end

  def test_get_todos
    results = @todout.get_todo_data("sampleproj", [ "subA/ignoreMeSubA", "ignoreMe" ], [ "b.txt" ])
    sr = results.map do |h|
      "#{h['file']}; #{h['line']}; #{h['group']}"
    end
    expected = [
      "./a.txt; TODO group B: another thing; group B",
      "./a.txt; TODO groupA: something; groupA",
      "./subA/subAfile.txt; todo subafile.txt; "
    ]
    assert_equal(expected, sr.sort, "comments with groups")
  end
  
end
