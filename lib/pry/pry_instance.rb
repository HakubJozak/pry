require "pry/command_processor.rb"

class Pry

  attr_accessor :input
  attr_accessor :output
  attr_accessor :commands
  attr_accessor :print
  attr_accessor :exception_handler
  attr_accessor :hooks
  attr_accessor :custom_completions

  attr_accessor :binding_stack

  attr_accessor :last_result
  attr_accessor :last_exception
  attr_accessor :last_file
  attr_accessor :last_dir

  attr_reader :input_array
  attr_reader :output_array

  # Create a new `Pry` object.
  # @param [Hash] options The optional configuration parameters.
  # @option options [#readline] :input The object to use for input.
  # @option options [#puts] :output The object to use for output.
  # @option options [Pry::CommandBase] :commands The object to use for commands.
  # @option options [Hash] :hooks The defined hook Procs
  # @option options [Array<Proc>] :prompt The array of Procs to use for the prompts.
  # @option options [Proc] :print The Proc to use for the 'print'
  #   component of the REPL. (see print.rb)
  def initialize(options={})
    refresh(options)

    @command_processor = CommandProcessor.new(self)
    @binding_stack     = []
  end

  # Refresh the Pry instance settings from the Pry class.
  # Allows options to be specified to override settings from Pry class.
  # @param [Hash] options The options to override Pry class settings
  #   for this instance.
  def refresh(options={})
    defaults   = {}
    attributes = [
                   :input, :output, :commands, :print,
                   :exception_handler, :hooks, :custom_completions,
                   :prompt, :memory_size
                 ]

    attributes.each do |attribute|
      defaults[attribute] = Pry.send attribute
    end

    defaults.merge!(options).each do |key, value|
      send "#{key}=", value
    end

    true
  end

  # The current prompt.
  # This is the prompt at the top of the prompt stack.
  #
  # @example
  #    self.prompt = Pry::SIMPLE_PROMPT
  #    self.prompt # => Pry::SIMPLE_PROMPT
  #
  # @return [Array<Proc>] Current prompt.
  def prompt
    prompt_stack.last
  end

  def prompt=(new_prompt)
    if prompt_stack.empty?
      push_prompt new_prompt
    else
      prompt_stack[-1] = new_prompt
    end
  end

  # Injects a local variable into the provided binding.
  # @param [String] name The name of the local to inject.
  # @param [Object] value The value to set the local to.
  # @param [Binding] b The binding to set the local on.
  # @return [Object] The value the local was set to.
  def inject_local(name, value, b)
    Thread.current[:__pry_local__] = value
    b.eval("#{name} = Thread.current[:__pry_local__]")
  ensure
    Thread.current[:__pry_local__] = nil
  end

  # @return [Integer] The maximum amount of objects remembered by the inp and
  #   out arrays. Defaults to 100.
  def memory_size
    @output_array.max_size
  end

  def memory_size=(size)
    @input_array  = Pry::HistoryArray.new(size)
    @output_array = Pry::HistoryArray.new(size)
  end

  # Execute the hook `hook_name`, if it is defined.
  # @param [Symbol] hook_name The hook to execute
  # @param [Array] args The arguments to pass to the hook.
  def exec_hook(hook_name, *args, &block)
    hooks[hook_name].call(*args, &block) if hooks[hook_name]
  end

  # Make sure special locals exist at start of session
  def initialize_special_locals(target)
    inject_local("_in_", @input_array, target)
    inject_local("_out_", @output_array, target)
    inject_local("_pry_", self, target)
    inject_local("_ex_", nil, target)
    inject_local("_file_", nil, target)
    inject_local("_dir_", nil, target)

    # without this line we get 1 test failure, ask Mon_Ouie
    set_last_result(nil, target)
    inject_local("_", nil, target)
  end
  private :initialize_special_locals

  def inject_special_locals(target)
    inject_local("_in_", @input_array, target)
    inject_local("_out_", @output_array, target)
    inject_local("_pry_", self, target)
    inject_local("_ex_", self.last_exception, target)
    inject_local("_file_", self.last_file, target)
    inject_local("_dir_", self.last_dir, target)
    inject_local("_", self.last_result, target)
  end

  # Initialize the repl session.
  # @param [Binding] target The target binding for the session.
  def repl_prologue(target)
    exec_hook :before_session, output, target, self
    initialize_special_locals(target)

    @input_array << nil # add empty input so inp and out match

    Pry.active_sessions += 1
    binding_stack.push target
  end

  # Clean-up after the repl session.
  # @param [Binding] target The target binding for the session.
  # @return [Object] The return value of the repl session (if one exists).
  def repl_epilogue(target, break_data)
    exec_hook :after_session, output, target, self

    Pry.active_sessions -= 1
    binding_stack.pop
    Pry.save_history if Pry.config.history.should_save && Pry.active_sessions == 0
    break_data
  end

  # Start a read-eval-print-loop.
  # If no parameter is given, default to top-level (main).
  # @param [Object, Binding] target The receiver of the Pry session
  # @return [Object] The target of the Pry session or an explictly given
  #   return value. If given return value is `nil` or no return value
  #   is specified then `target` will be returned.
  # @example
  #   Pry.new.repl(Object.new)
  def repl(target=TOPLEVEL_BINDING)
    target = Pry.binding_for(target)
    target_self = target.eval('self')

    repl_prologue(target)

    break_data = catch(:breakout) do
      loop do
        rep(binding_stack.last)
      end
    end

    return_value = repl_epilogue(target, break_data)
    return_value || target_self
  end

  # Perform a read-eval-print.
  # If no parameter is given, default to top-level (main).
  # @param [Object, Binding] target The receiver of the read-eval-print
  # @example
  #   Pry.new.rep(Object.new)
  def rep(target=TOPLEVEL_BINDING)
    target = Pry.binding_for(target)
    result = re(target)

    show_result(result) if should_print?
  end

  # Perform a read-eval
  # If no parameter is given, default to top-level (main).
  # @param [Object, Binding] target The receiver of the read-eval-print
  # @return [Object] The result of the eval or an `Exception` object in case of
  #   error. In the latter case, you can check whether the exception was raised
  #   or is just the result of the expression using #last_result_is_exception?
  # @example
  #   Pry.new.re(Object.new)
  def re(target=TOPLEVEL_BINDING)
    target = Pry.binding_for(target)

    if input == Readline
      # Readline tab completion
      Readline.completion_proc = Pry::InputCompleter.build_completion_proc target, instance_eval(&custom_completions)
    end

    # It's not actually redundant to inject them continually as we may have
    # moved into the scope of a new Binding (e.g the user typed `cd`)
    inject_special_locals(target)

    # loop until the user has typed a complete expression or invalid input.
    begin

      code = r(target, code || "")
      result = target.eval(code, Pry.eval_path, Pry.current_line);

    rescue SyntaxError => e
      retry if incomplete_user_input_exception?(e, caller)
      raise
    end

    set_last_result(result, target)
    result

  rescue RescuableException => e
    set_last_exception(e, target)
  ensure
    update_input_history(code)
  end

  # Read a single line and append it to the string so far.
  # If no parameter is given, default to top-level (main).
  # Pry commands are also accepted here and operate on the target.
  # @param [Object, Binding] target The receiver of the read.
  # @param [String] eval_string Optionally Prime `eval_string` with a start value.
  # @return [String] The Ruby expression.
  # @example
  #   Pry.new.r(Object.new)
  def r(target=TOPLEVEL_BINDING, eval_string="")
    target = Pry.binding_for(target)
    @suppress_output = false

    val = ""
    val = retrieve_line(eval_string, target)
    process_line(val, eval_string, target)

    @suppress_output = true if eval_string =~ /;\Z/ || eval_string.empty?

    eval_string
  end

  # Output the result or pass to an exception handler (if result is an exception).
  def show_result(result)
    if last_result_is_exception?
      exception_handler.call output, result
    else
      print.call output, result
    end
  rescue RescuableException => e
    # Being uber-paranoid here, given that this exception arose because we couldn't
    # serialize something in the user's program, let's not assume we can serialize
    # the exception either.
    begin
      output.puts "output error: #{e.inspect}"
    rescue RescuableException => e
      if last_result_is_exception?
        output.puts "output error: failed to show exception"
      else
        output.puts "output error: failed to show result"
      end
    end
  end

  # Read a line of input and check for ^d, also determine prompt to use.
  # This method should not need to be invoked directly.
  # @param [String] eval_string The cumulative lines of input.
  # @param [Binding] target The target of the session.
  # @return [String] The line received.
  def retrieve_line(eval_string, target)
    current_prompt = select_prompt(eval_string.empty?, target.eval('self'))
    val = readline(current_prompt)

    # exit session if we receive EOF character (^D)
    if !val
      output.puts ""
      Pry.config.control_d_handler.call(eval_string, self)
      ""
    else
      val
    end
  end

  # Process the line received.
  # This method should not need to be invoked directly.
  # @param [String] val The line to process.
  # @param [String] eval_string The cumulative lines of input.
  # @param [Binding] target The target of the Pry session.
  def process_line(val, eval_string, target)
    result = @command_processor.process_commands(val, eval_string, target)

    # set a temporary (just so we can inject the value we want into eval_string)
    Thread.current[:__pry_cmd_result__] = result

    # note that `result` wraps the result of command processing; if a
    # command was matched and invoked then `result.command?` returns true,
    # otherwise it returns false.
    if result.command? && !result.void_command?

      # the command that was invoked was non-void (had a return value) and so we make
      # the value of the current expression equal to the return value
      # of the command.
      eval_string.replace "Thread.current[:__pry_cmd_result__].retval\n"
    else
      # only commands should have an empty `val`
      # so this ignores their result
      eval_string << "#{val.rstrip}\n" if !val.empty?
    end
  end

  # Set the last result of an eval.
  # This method should not need to be invoked directly.
  # @param [Object] result The result.
  # @param [Binding] target The binding to set `_` on.
  def set_last_result(result, target)
    @last_result_is_exception = false
    @output_array << result

    self.last_result = result
  end

  # Set the last exception for a session.
  # This method should not need to be invoked directly.
  # @param [Exception] ex The exception.
  # @param [Binding] target The binding to set `_ex_` on.
  def set_last_exception(ex, target)
    class << ex
      attr_accessor :file, :line
    end

    ex.backtrace.first =~ /(.*):(\d+)/
    ex.file, ex.line = $1, $2.to_i

    @last_result_is_exception = true
    @output_array << ex

    self.last_exception = ex
  end

  # Update Pry's internal state after evalling code.
  # This method should not need to be invoked directly.
  # @param [String] code The code we just eval'd
  def update_input_history(code)
    # Always push to the @input_array as the @output_array is always pushed to.
    @input_array << code
    if code
      Pry.line_buffer.push(*code.each_line)
      Pry.current_line += code.each_line.count
    end
  end

  # @return [Boolean] True if the last result is an exception that was raised,
  #   as opposed to simply an instance of Exception (like the result of
  #   Exception.new)
  def last_result_is_exception?
    @last_result_is_exception
  end

  # Returns the next line of input to be used by the pry instance.
  # This method should not need to be invoked directly.
  # @param [String] current_prompt The prompt to use for input.
  # @return [String] The next line of input.
  def readline(current_prompt="> ")

    if input == Readline
      line = input.readline(current_prompt, false)
      Pry.history << line.dup if line
      line
    else
      begin
        if input.method(:readline).arity == 1
          input.readline(current_prompt)
        else
          input.readline
        end

      rescue EOFError
        self.input = Pry.input
        ""
      end
    end
  end

  # Whether the print proc should be invoked.
  # Currently only invoked if the output is not suppressed OR the last result
  # is an exception regardless of suppression.
  # @return [Boolean] Whether the print proc should be invoked.
  def should_print?
    !@suppress_output || last_result_is_exception?
  end

  # Returns the appropriate prompt to use.
  # This method should not need to be invoked directly.
  # @param [Boolean] first_line Whether this is the first line of input
  #   (and not multi-line input).
  # @param [Object] target_self The receiver of the Pry session.
  # @return [String] The prompt.
  def select_prompt(first_line, target_self)

    if first_line
      Array(prompt).first.call(target_self, binding_stack.size - 1, self)
    else
      Array(prompt).last.call(target_self, binding_stack.size - 1, self)
    end
  end

  # the array that the prompt stack is stored in
  def prompt_stack
    @prompt_stack ||= Array.new
  end
  private :prompt_stack

  # Pushes the current prompt onto a stack that it can be restored from later.
  # Use this if you wish to temporarily change the prompt.
  # @param [Array<Proc>] new_prompt
  # @return [Array<Proc>] new_prompt
  # @example
  #    new_prompt = [ proc { '>' }, proc { '>>' } ]
  #    push_prompt(new_prompt) # => new_prompt
  def push_prompt(new_prompt)
    prompt_stack.push new_prompt
  end

  # Pops the current prompt off of the prompt stack.
  # If the prompt you are popping is the last prompt, it will not be popped.
  # Use this to restore the previous prompt.
  # @return [Array<Proc>] Prompt being popped.
  # @example
  #    prompt1 = [ proc { '>' }, proc { '>>' } ]
  #    prompt2 = [ proc { '$' }, proc { '>' } ]
  #    pry = Pry.new :prompt => prompt1
  #    pry.push_prompt(prompt2)
  #    pry.pop_prompt # => prompt2
  #    pry.pop_prompt # => prompt1
  #    pry.pop_prompt # => prompt1
  def pop_prompt
    prompt_stack.size > 1 ? prompt_stack.pop : prompt
  end

  # Check whether the exception indicates that the user should input more.
  #
  # The first part of the check verifies that the exception was raised from
  # the input to the eval, taking care not to be confused if the input contains
  # an eval() with incomplete syntax.
  #
  # @param [SyntaxError] the exception object that was raised.
  # @param [Array<String>] The stack frame of the function that executed eval.
  # @return [Boolean]
  #
  def incomplete_user_input_exception?(ex, stack)

    # deliberate use of ^ instead of \A, error messages can be two lines long.
    from_pry_input = /^#{Regexp.escape(Pry.eval_path)}/

    return false unless SyntaxError === ex && ex.message =~ from_pry_input

    case ex.message
    # end-of file in matz-ruby, jruby, and iron ruby. "quoted string" is also iron ruby, string and regexp ae shared.
    when /unexpected (\$end|end-of-file|END_OF_FILE)/, /unterminated (quoted string|string|regexp) meets end of file/,
        # All of these are rbx...
        /missing 'end' for/, /: expecting '[})\]]'$/, /can't find string ".*" anywhere before EOF/

      backtrace = ex.backtrace
      backtrace = backtrace.drop(1) if RUBY_VERSION =~ /1.8/ && RUBY_PLATFORM !~ /java/

      return backtrace.grep(from_pry_input).count <= stack.grep(from_pry_input).count
    end
  end
end
