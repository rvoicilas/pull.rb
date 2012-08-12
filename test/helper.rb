require 'test/unit'
require 'mocha'
require 'fileutils'
require 'logger'
require 'puller'

# I do want assert_true and assert_false
module Test::Unit::Assertions
  def assert_true(object, message='')
    assert_equal true, object, message
  end

  def assert_false(object, message='')
    assert_equal false, object, message
  end
end
