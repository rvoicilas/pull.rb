require_relative './helper'

module Pull
 describe Cli do
    describe 'when no branch is provided' do
      it 'should display an error' do
        _, err = capture_io do
          execute_and_rescue { Cli.new([]) }
        end
        expected = <<-EOS
Error: Please provide a branch name.
Try --help for help.
EOS
        assert_equal expected, err
      end
    end

    describe 'when a missing config file is provided' do
      it 'should print out an error message' do
        _, err = capture_io do
          execute_and_rescue { Cli.new(['--file', 'fake!', 'master']) }
        end
        expected = <<-EOS
Error: Missing config file, expected to be at fake!.
Try --help for help.
EOS
        assert_equal expected, err
      end
    end

    describe 'when the default config file is missing' do
      it 'should print out an error message' do
        _, err = capture_io do
          File.expects(:exists?).returns(false)
          execute_and_rescue { Cli.new(['master']) }
        end
        default_config_path = File.absolute_path(File.join(File.dirname(__FILE__), '..',
                                                           Pull::DEFAULT_CONFIG_NAME))
        expected = <<-EOS
Error: Missing default config file, expected to be at #{default_config_path}.
Try --help for help.
EOS
        assert_equal expected, err
      end
    end

    describe 'when --quiet is passed in' do
      it 'should not display anything to stdout' do
        out, _ = capture_io do
          YAML.expects(:load_file).returns({})
          Cli.new(['--quiet', 'master']).run
        end
        assert out.empty?, "Something got logged to stdout: #{out}"
      end
    end
  end
end
