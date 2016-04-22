require 'cucumber/nested_steps/plugin'

World(Cucumber::NestedSteps::Dsl)
Cucumber::Runtime::SupportCode.send :include, Cucumber::NestedSteps::DynamicSupportCode
