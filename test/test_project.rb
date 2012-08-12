require File.expand_path('../helper', __FILE__)

class ProjectTest < Test::Unit::TestCase
  def setup
    logger = Logger.new("/dev/null")
    @project = Project.new(logger)
  end

  def test_git_project_yes
    project_dir = "here"
    FileUtils.mkdir_p "#{project_dir}/.git"

    assert_true @project.git_project?(project_dir)

    FileUtils.rmtree project_dir
  end

  def test_git_project_no
    project_dir = "there"
    FileUtils.mkdir_p project_dir

    assert_false @project.git_project?(project_dir)

    FileUtils.rmtree project_dir
  end

  def test_has_local_changes_yes
    @project.stubs(:run_command).returns(["list element"])
    assert_true @project.has_local_changes?("some project directory")
  end

  def test_has_local_changes_no
    @project.stubs(:run_command).returns([])
    assert_false @project.has_local_changes?("project")
  end

  def test_branch_is_valid_yes
    @project.stubs(:run_command).returns(["12121323hashash branch\n"])
    assert_true @project.branch_is_valid?("project", "branch")
  end

  def test_branch_is_valid_no
    @project.stubs(:run_command).returns([])
    assert_false @project.branch_is_valid?("project", "branch")
  end

  def test_switch_branch_yes
    # make sure that the run_command has been called twice - once for checking
    # whether we're on the right branch and the second time for moving the code
    # on the required branch
    @project.expects(:run_command).returns(["something with newlines\n\n"]).twice
    @project.switch_branch("project", "master")
  end

  def test_switch_branch_no
    @project.expects(:run_command).returns(["master"])
    @project.switch_branch("project", "master")
  end

  def test_count_project_stashes
    @project.stubs(:run_command).returns(["2"]).once
    assert_equal 2, @project.count_project_stashes("kpi")
  end

  def test_pull_upstream
    @project.stubs(:run_command).once
    @project.pull_upstream "/uhuu/project", "master"
  end

  def test_run_not_a_git_project
    @project.stubs(:git_project?).returns(false)
    assert_false @project.run("myproject", "master")
  end

  def test_run_branch_is_not_valid
    @project.stubs(:git_project?).returns(true)
    @project.stubs(:branch_is_valid?).returns(false)
    assert_false @project.run("myproject", "some branch")
  end

  def test_run_has_local_changes
    @project.stubs(:git_project?).returns(true)
    @project.stubs(:has_local_changes?).returns(true)
    assert_false @project.run("myproject", "master")
  end

  def test_run_pull_upstream_called
    @project.stubs(:git_project?).returns(true)
    @project.stubs(:has_local_changes?).returns(false)
    @project.stubs(:count_project_stashes).returns(0)
    @project.stubs(:branch_is_valid?).returns(true)
    @project.stubs(:switch_branch)
    # this is what we're actually testing
    @project.stubs(:pull_upstream).once
    @project.run("myproject", "master")
  end
end
