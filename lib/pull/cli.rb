module Pull
  class Cli
    def initialize args
      # Do not allow ctrl-c, as you don't know in which state you're going
      # to leave your project.
      trap(:INT) {}

      @opts = Trollop.options args do
        banner 'Usage: pull.rb [options] branch'
        banner 'Options:'
        opt :quiet, 'Do not display things I am doing', :default => false
        opt :file, 'A yaml file with project paths', :type => String
        opt :no_color, 'Do not use colors for the output', :default => false
        opt :no_fetch, 'Do not fetch data from remote', :default => false
      end

      Trollop::die "Please provide a branch name" if args.first.nil?
      @branch = args.first
      @config = YAML.load_file(handle_config)

      # Turn off colored logging
      if @opts[:no_color]
        Sickill::Rainbow.enabled = false
      end
    end

    # Returns a full path to the config file (either to the one provided
    # by the user or to the default one) or raises a SystemExit if a path
    # to any of those doesn't exist.
    def handle_config
      if @opts[:file].nil?
        default = true
        components = [File.dirname(__FILE__), '..', '..', Pull::DEFAULT_CONFIG_NAME]
        file = File.absolute_path(File.join(components))
      else
        default = false
        file = @opts[:file]
      end

      if not File.exists? file
        if default
          msg = "Missing default config file, expected to be at #{file}"
        else
          msg = "Missing config file, expected to be at #{file}"
        end
        Trollop::die msg
      else
        file
      end
    end

    # Returns a STDOUT logger if --quiet|-q not provided.
    # Otherwise a /dev/null logger is returned.
    def get_logger
      stream = STDOUT
      if @opts[:quiet]
        stream = '/dev/null'
      end
      logger = Logger.new(stream)
      logger.level = Logger::INFO
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
      logger
    end

    # Goes over each project and makes sure that changes
    # from that scm are pulled in from the branch provided
    # to the command line.
    def run_projects puller, projects, logger
      status_queue = Queue.new
      projects_threads = []
      
      projects.each { |project|
        thread = Thread.new do
          status = puller.run(project, @branch)
          status_queue << 1 unless status
        end
        projects_threads << thread
      }
      
      projects_threads.each { |thread|
        thread.join
      }

      # Since we're adding only when failures happen,
      # the length of the queue should be good enough for
      # figuring out the number of failures
      status_queue.length
    end

    def run
      logger = get_logger
      logger.info(Rainbow("Switching to #{@branch}").green)

      git_projects = @config['git']
      failed = 0
      if not git_projects.nil?
        git = Pull::Git.new(logger, !@opts[:no_fetch])
        failed += run_projects(git, git_projects, logger)
      end

      if failed.nonzero?
        logger.info(Rainbow(
            "Done. ( #{failed} projects untouched )").green)
      else
        logger.info(Rainbow("Done.").green)
      end

    end
  end
end
