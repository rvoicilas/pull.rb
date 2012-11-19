require 'logger/colors'
require 'open3'
require 'trollop'
require 'yaml'

module Pull
  DEFAULT_CONFIG_NAME = 'config.yml'

  require_relative 'pull/git'
  require_relative 'pull/cli'
end