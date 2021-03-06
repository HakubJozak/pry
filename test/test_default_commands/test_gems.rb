require 'helper'

describe "Pry::DefaultCommands::Gems" do
  describe "gem-list" do

    # fixing bug for 1.8 compat
    it 'should not raise when invoked' do
      str_output = StringIO.new
      Pry.start self, :input => InputTester.new("gem-list", "exit-all"), :output => str_output
      str_output.string.should.not =~ /NoMethodError/
    end
  end
end

