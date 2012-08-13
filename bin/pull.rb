#! /usr/bin/env ruby

thisfile = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
libdir = File.absolute_path(File.join(File.dirname(thisfile), '..', 'lib'))
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include? libdir

require 'logger/colors'
require 'yaml'
require 'puller'

branch = ARGV[0]
if branch.nil?
  puts "Usage: ruby pull.rb <git-branch>"
  exit
end

logger = Logger.new(STDOUT)
logger.level = Logger::INFO
logger.formatter = proc do |severity, datetime, progname, msg|
  "#{msg}\n"
end

puller = Project.new(logger)

config = File.absolute_path(File.join(File.dirname(thisfile), '..', 'config.yml'))
yaml = YAML.load_file(config)
projects = yaml["projects"]

failed = 0
logger.info("Switching to #{branch}")
projects.each { |project|
  status = puller.run(project, branch)
  failed += 1 unless status
}

if failed.nonzero?
  logger.info("Done. ( #{failed} projects untouched )")
else
  logger.info("Done.")
end
