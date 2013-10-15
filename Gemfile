source "https://rubygems.org"

gemspec

gem 'debugger', platforms: :mri_19
gem 'byebug', platforms: :mri_20

platforms :mri_19, :mri_20 do
  gem 'simplecov', require: false
  gem 'coveralls', require: false
end

platforms :ruby do
  gem "sqlite3"
end

platforms :jruby do
  gem "minitest", ">= 3.0"
  gem "activerecord-jdbcsqlite3-adapter", ">= 1.3.0.beta2"
end

version = ENV["RAILS_VERSION"] || "4.0"

eval_gemfile File.expand_path("../gemfiles/#{version}.gemfile", __FILE__)
