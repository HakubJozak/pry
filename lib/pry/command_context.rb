class Pry
  # Command contexts are the objects runing each command.
  # Helper modules can be mixed into this class.
  class CommandContext
    attr_accessor :output
    attr_accessor :target
    attr_accessor :opts

    include Pry::CommandBase::CommandBaseHelpers
    include Pry::CommandHelpers
  end
end