module Cucumber
  module NestedSteps
    module Dsl
      # Run a single Gherkin step
      # @example Call another step
      #   step "I am logged in"
      # @example Call a step with quotes in the name
      #   step %{the user "Dave" is logged in}
      # @example Passing a table
      #   step "the following users exist:", table(%{
      #     | name  | email           |
      #     | Matt  | matt@matt.com   |
      #     | Aslak | aslak@aslak.com |
      #   })
      # @example Passing a multiline string
      #   step "the email should contain:", "Dear sir,\nYou've won a prize!\n"
      # @param [String] name The name of the step
      # @param [String,Cucumber::Ast::DocString,Cucumber::Ast::Table] multiline_argument
      def step(name, raw_multiline_arg=nil)
        location = Core::Ast::Location.of_caller
        @__cucumber_runtime.invoke_dynamic_step(name, MultilineArgument.from(raw_multiline_arg, location))
      end

      # Run a snippet of Gherkin
      # @example
      #   steps %{
      #     Given the user "Susan" exists
      #     And I am logged in as "Susan"
      #   }
      # @param [String] steps_text The Gherkin snippet to run
      def steps(steps_text)
        location = Core::Ast::Location.of_caller
        @__cucumber_runtime.invoke_dynamic_steps(steps_text, @__natural_language, location)
      end
    end

    require 'forwardable'
    class StepInvoker

      def initialize(support_code)
        @support_code = support_code
      end

      def steps(steps)
        steps.each { |step| step(step) }
      end

      def step(step)
        location = Core::Ast::Location.of_caller
        @support_code.invoke_dynamic_step(step[:text], multiline_arg(step, location))
      end

      def multiline_arg(step, location)
        if argument = step[:argument]
          if argument[:type] == :DocString
            MultilineArgument.doc_string(argument[:content], argument[:content_type], location)
          else
            MultilineArgument::DataTable.from(argument[:rows].map { |row| row[:cells].map { |cell| cell[:value] } })
          end
        else
          MultilineArgument.from(nil)
        end
      end
    end

    module DynamicSupportCode
      # Invokes a series of steps +steps_text+. Example:
      #
      #   invoke(%Q{
      #     Given I have 8 cukes in my belly
      #     Then I should not be thirsty
      #   })
      def invoke_dynamic_steps(steps_text, i18n, location)
        parser = Cucumber::Gherkin::StepsParser.new(StepInvoker.new(self), i18n.iso_code)
        parser.parse(steps_text)
      end

      # @api private
      # This allows users to attempt to find, match and execute steps
      # from code as the features are running, as opposed to regular
      # steps which are compiled into test steps before execution.
      #
      # These are commonly called nested steps.
      def invoke_dynamic_step(step_name, multiline_argument, location=nil)
        matches = step_matches(step_name)
        raise UndefinedDynamicStep, step_name if matches.empty?
        matches.first.invoke(multiline_argument)
      end

      def step_matches(step_name)
        StepMatchSearch.new(@ruby.method(:step_matches), @configuration).call(step_name)
      end
    end

  end
end

