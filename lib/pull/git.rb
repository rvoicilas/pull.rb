module Pull
  class Git
    def initialize logger
      @logger = logger
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
        @logger.info(msg.color(:green))
      end
    end

    # Public: Get the count of the `git stash` command
    # Returns an int with the number of stashes the current project has
    def count_project_stashes project_dir
      command = "git stash list | wc -l"
      stashes = run_command(command, project_dir)
      stashes[0].to_i
    end

    # Public: Pull the code from upstream for the specified project
    def pull_upstream project_dir, branch
      command = "git pull --rebase origin #{branch}"
      run_command(command, project_dir)
    end

    # Public: Pulls code from upstream for a git project
    #
    # Returns whether a project has been moved on the required branch or not
    def run project, branch
      basename = File.basename project

      if !git_project? project
        @logger.error("#{basename} is not a valid git project".color(:red))
        return false
      end

      if not branch_is_valid? project, branch
        @logger.error("Branch #{branch} is not valid for project #{basename}".color(:red))
        return false
      end

      if has_local_changes? project
        msg = ("Local changes found for #{basename}, " +
                      "won't chase pulling upstream anymore")
        @logger.error(msg.color(:red))
        return false
      end

      count_stashes = count_project_stashes project
      switch_branch project, branch
      pull_upstream project, branch

      # Display some info about the project that we just updated
      stash_info = ''
      if count_stashes.nonzero?
        stash_info = ' ( ' + count_stashes.to_s + ' existent stash'
        if count_stashes > 1
          # add the plural
          stash_info = stash_info + 'es )'
        else
          stash_info = stash_info  + ' )'
        end
      end

      @logger.info("Done getting data from upstream for #{basename}#{stash_info}".color(:green))

      return true
    end
  end
end
