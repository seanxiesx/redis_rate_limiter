require "rubygems"
require "bundler"
Bundler.setup

require "rake"
require "rspec"
require "rspec/core/rake_task"

$:.push File.expand_path("../lib", __FILE__)
require "redis_rate_limiter"

task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end
