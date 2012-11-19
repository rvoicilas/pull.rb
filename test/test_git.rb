require_relative('./helper')
require 'test/unit'

# I do want assert_true and assert_false
module Test::Unit::Assertions
  def assert_true(object, message='')
    assert_equal true, object, message
  end

  def assert_false(object, message='')
    assert_equal false, object, message
  end
end

class GitTest < Test::Unit::TestCase
  def setup
    logger = Logger.new("/dev/null")
    @git = Pull::Git.new(logger)
  end

  def test_git_project_yes
    project_dir = "here"
    FileUtils.mkdir_p "#{project_dir}/.git"

    assert_true @git.git_project?(project_dir)

    FileUtils.rmtree project_dir
  end

  def test_git_project_no
    project_dir = "there"
    FileUtils.mkdir_p project_dir

    assert_false @git.git_project?(project_dir)

    FileUtils.rmtree project_dir
  end

  def test_has_local_changes_yes
    @git.stubs(:run_command).returns(["list element"])
    assert_true @git.has_local_changes?("some project directory")
  end

  def test_has_local_changes_no
    @git.stubs(:run_command).returns([])
    assert_false @git.has_local_changes?("project")
  end

  def test_branch_is_valid_yes
    @git.stubs(:run_command).returns(["12121323hashash branch\n"])
    assert_true @git.branch_is_valid?("project", "branch")
  end

  def test_branch_is_valid_no
    @git.stubs(:run_command).returns([])
    assert_false @git.branch_is_valid?("project", "branch")
  end

  def test_switch_branch_yes
    # make sure that the run_command has been called twice - once for checking
    # whether we're on the right branch and the second time for moving the code
    # on the required branch
    @git.expects(:run_command).returns(["something with newlines\n\n"]).twice
    @git.switch_branch("project", "master")
  end

  def test_switch_branch_no
    @git.expects(:run_command).returns(["master"])
    @git.switch_branch("project", "master")
  end

  def test_count_project_stashes
    @git.stubs(:run_command).returns(["2"]).once
    assert_equal 2, @git.count_project_stashes("kpi")
  end

  def test_pull_upstream
    @git.stubs(:run_command).once
    @git.pull_upstream "/uhuu/project", "master"
  end

  def test_run_not_a_git_project
    @git.stubs(:git_project?).returns(false)
    assert_false @git.run("myproject", "master")
  end

  def test_run_branch_is_not_valid
    @git.stubs(:git_project?).returns(true)
    @git.stubs(:branch_is_valid?).returns(false)
    assert_false @git.run("myproject", "some branch")
  end

  def test_run_has_local_changes
    @git.stubs(:git_project?).returns(true)
    @git.stubs(:has_local_changes?).returns(true)
    assert_false @git.run("myproject", "master")
  end

  def test_run_pull_upstream_called
    @git.stubs(:git_project?).returns(true)
    @git.stubs(:has_local_changes?).returns(false)
    @git.stubs(:count_project_stashes).returns(0)
    @git.stubs(:branch_is_valid?).returns(true)
    @git.stubs(:switch_branch)
    # this is what we're actually testing
    @git.stubs(:pull_upstream).once
    @git.run("myproject", "master")
  end
end