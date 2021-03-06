# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pry}
  s.version = "0.9.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mair (banisterfiend)"]
  s.date = %q{2011-09-09}
  s.description = %q{An IRB alternative and runtime developer console}
  s.email = %q{jrmair@gmail.com}
  s.executables = ["pry"]
  s.files = [".document", ".gemtest", ".gitignore", ".yardopts", "CHANGELOG", "CONTRIBUTORS", "LICENSE", "README.markdown", "Rakefile", "TODO", "bin/pry", "examples/example_basic.rb", "examples/example_command_override.rb", "examples/example_commands.rb", "examples/example_hooks.rb", "examples/example_image_edit.rb", "examples/example_input.rb", "examples/example_input2.rb", "examples/example_output.rb", "examples/example_print.rb", "examples/example_prompt.rb", "examples/helper.rb", "lib/pry.rb", "lib/pry/command_context.rb", "lib/pry/command_processor.rb", "lib/pry/command_set.rb", "lib/pry/commands.rb", "lib/pry/completion.rb", "lib/pry/config.rb", "lib/pry/core_extensions.rb", "lib/pry/custom_completions.rb", "lib/pry/default_commands/basic.rb", "lib/pry/default_commands/context.rb", "lib/pry/default_commands/documentation.rb", "lib/pry/default_commands/easter_eggs.rb", "lib/pry/default_commands/gems.rb", "lib/pry/default_commands/input.rb", "lib/pry/default_commands/introspection.rb", "lib/pry/default_commands/ls.rb", "lib/pry/default_commands/shell.rb", "lib/pry/extended_commands/experimental.rb", "lib/pry/extended_commands/user_command_api.rb", "lib/pry/helpers.rb", "lib/pry/helpers/base_helpers.rb", "lib/pry/helpers/command_helpers.rb", "lib/pry/helpers/text.rb", "lib/pry/history.rb", "lib/pry/history_array.rb", "lib/pry/plugins.rb", "lib/pry/pry_class.rb", "lib/pry/pry_instance.rb", "lib/pry/version.rb", "pry.gemspec", "test/helper.rb", "test/test_command_helpers.rb", "test/test_command_processor.rb", "test/test_command_set.rb", "test/test_completion.rb", "test/test_default_commands.rb", "test/test_default_commands/test_context.rb", "test/test_default_commands/test_documentation.rb", "test/test_default_commands/test_gems.rb", "test/test_default_commands/test_input.rb", "test/test_default_commands/test_introspection.rb", "test/test_default_commands/test_shell.rb", "test/test_history_array.rb", "test/test_pry.rb", "test/test_pry_history.rb", "test/test_pry_output.rb", "test/test_special_locals.rb", "test/testrc", "wiki/Customizing-pry.md", "wiki/Home.md"]
  s.homepage = %q{http://pry.github.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{An IRB alternative and runtime developer console}
  s.test_files = ["test/helper.rb", "test/test_command_helpers.rb", "test/test_command_processor.rb", "test/test_command_set.rb", "test/test_completion.rb", "test/test_default_commands.rb", "test/test_default_commands/test_context.rb", "test/test_default_commands/test_documentation.rb", "test/test_default_commands/test_gems.rb", "test/test_default_commands/test_input.rb", "test/test_default_commands/test_introspection.rb", "test/test_default_commands/test_shell.rb", "test/test_history_array.rb", "test/test_pry.rb", "test/test_pry_history.rb", "test/test_pry_output.rb", "test/test_special_locals.rb", "test/testrc"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby_parser>, [">= 2.0.5"])
      s.add_runtime_dependency(%q<coderay>, [">= 0.9.8"])
      s.add_runtime_dependency(%q<slop>, ["~> 2.1.0"])
      s.add_runtime_dependency(%q<method_source>, [">= 0.6.5"])
      s.add_development_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_development_dependency(%q<open4>, ["~> 1.0.1"])
    else
      s.add_dependency(%q<ruby_parser>, [">= 2.0.5"])
      s.add_dependency(%q<coderay>, [">= 0.9.8"])
      s.add_dependency(%q<slop>, ["~> 2.1.0"])
      s.add_dependency(%q<method_source>, [">= 0.6.5"])
      s.add_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_dependency(%q<open4>, ["~> 1.0.1"])
    end
  else
    s.add_dependency(%q<ruby_parser>, [">= 2.0.5"])
    s.add_dependency(%q<coderay>, [">= 0.9.8"])
    s.add_dependency(%q<slop>, ["~> 2.1.0"])
    s.add_dependency(%q<method_source>, [">= 0.6.5"])
    s.add_dependency(%q<bacon>, [">= 1.1.0"])
    s.add_dependency(%q<open4>, ["~> 1.0.1"])
  end
end
