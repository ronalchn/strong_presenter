require 'rake/testtask'

test_task = if Rails.version.to_f < 3.2
  require 'rails/test_unit/railtie'
  Rake::TestTask
else
  require 'rails/test_unit/sub_test_task'
  Rails::SubTestTask
end

namespace :test do
  test_task.new(:presenters => "test:prepare") do |t|
    t.libs << "test"
    t.pattern = "test/presenters/**/*_test.rb"
  end
end

if Rake::Task.task_defined?('test:run')
  Rake::Task['test:run'].enhance do
    Rake::Task['test:presenters'].invoke
  end
end
