module Pull
  class Git
    attr_accessor :should_fetch

    def initialize logger, should_fetch
      @logger = logger
      @should_fetch = should_fetch
    end

    # Public: Runs an external unix command.
    #
    # command - The unix command to run
    # project_dir - A full path to the root of the project
    #
    # Returns the stdout; does not take into account stdin or stderr
    def run_command command, project_dir
      command = "cd #{project_dir} && #{command}"
      _, stdout, _ = Open3.popen3(command)
      stdout.readlines
    end

    # Public: Checks for a valid git project directory.
    #
    # project_dir - The String that points to the root folder of a project
    #
    # Examples
    #
    # git_project?("/tmp/my-git-project")
    # # => true
    #
    # Returns a boolean of whether the passed in directory is a git project or not.
    def git_project? project_dir
      File.directory?(File::join(project_dir, '.git'))
    end

    # Public: Check to see whether a git project has local changes.
    # It doesn't take into account files that are on disk in the project's root,
    # but are not already checked in source control.
    #
    # project_dir - The String that points to the root folder of a project
    #
    # Returns a boolean of whether the project has local changes or not.
    def has_local_changes? project_dir
      command = "git status --porcelain | perl -lane 'print @F[1] unless @F[0] eq \"??\"'"
      stdout = run_command(command, project_dir)
      return !stdout.length.zero?
    end

    # Public: Check whether a branch is valid or not in the context of the given project.
    # When a branch does not exist, some error message is written to stderr, which this
    # method won't notice because it only gets stdout (which will be an empty list).
    def branch_is_valid? project_dir, branch
      command = "git show-ref --verify refs/heads/#{branch}"
      output = run_command(command, project_dir)
      output.length > 0
    end

    # Public: Switch project_dir to the required git branch.
    def switch_branch project_dir, branch
      check_command = "git branch | perl -lane 'print @F[1] if scalar(@F) > 1'"
      current_branch = run_command(check_command, project_dir)[0]
      current_branch = current_branch.gsub("\n", "")
      if current_branch != branch
        switch_command = "git checkout #{branch}"
        run_command(switch_command, project_dir)
        msg = "Switched branches for #{File.basename project_dir} " +
                     "(#{current_branch} -> #{branch})"
        @logger.info(Rainbow(msg).green)
      end
    end

    # Public: Get the count of the `git stash` command
    # Returns an int with the number of stashes the current project has
    def count_project_stashes project_dir
      command = "git stash list | wc -l"
      stashes = run_command(command, project_dir)
      stashes[0].to_i
    end

    # Public: Returns a string with info about the current stashes
    def get_stash_info count_stashes
      if count_stashes.zero?
        return ''
      end
      if count_stashes > 1
        return ' ( ' + count_stashes.to_s + ' existent stashes )'
      else
        return ' ( ' + count_stashes.to_s + ' existent stash )'
      end
    end

    # Public: Pull the code from upstream for the specified project
    def pull_upstream project_dir, branch
      command = "git pull --rebase origin #{branch}"
      run_command(command, project_dir)

      # Also, run a fetch so that the index is updated and git status
      # doesn't return false positives
      command = "git fetch origin #{branch}"
      run_command(command, project_dir)
    end

    # Public: Pulls code from upstream for a git project
    #
    # Returns whether a project has been moved on the required branch or not
    def run project, branch
      basename = File.basename project

      if !git_project? project
        @logger.error(Rainbow(
            "#{basename} is not a valid git project").red)
        return false
      end

      if not branch_is_valid? project, branch
        @logger.error(Rainbow(
            "Branch #{branch} is not valid for project #{basename}").red)
        return false
      end

      if has_local_changes? project
        msg = ("Local changes found for #{basename}, " +
                      "won't chase pulling upstream anymore")
        @logger.error(Rainbow(msg).red)
        return false
      end

      switch_branch project, branch

      if @should_fetch
        pull_upstream project, branch
        stash_msg = get_stash_info(count_project_stashes project)
        logmsg = ("Done getting data from upstream for " +
                  "#{basename}#{stash_msg}")
        @logger.info(Rainbow(logmsg).green)
      end

      return true
    end
  end
end
