require 'minitest/autorun'
require 'mocha/setup'
require 'fileutils'
require 'logger'

require_relative '../lib/pull'


# Execute a block of code and rescue on some
# predefined exceptions (i.e SystemExit) so that
# tests don't kill.
def execute_and_rescue
  begin
    yield if block_given?
  rescue SystemExit
  end
end
