# tax-data-generator/Gemfile
source 'https://rubygems.org'

# Specify Ruby version (matches workflow)
ruby '~> 3.2.0'

# Core gems
gem 'rake', '~> 13.0'
gem 'csv', '~> 3.2'
gem 'date', '~> 3.2'

# Data generation
gem 'faker', '~> 3.2', require: false
gem 'activesupport', '~> 7.0', require: false  # For time calculations

# Development/Test gems
group :development, :test do
  gem 'rspec', '~> 3.12'
  gem 'rubocop', '~> 1.50', require: false
  gem 'rubocop-rake', '~> 0.6', require: false
  gem 'rubocop-rspec', '~> 2.20', require: false
end

# GitHub Actions specific (not needed for local development)
group :github_actions do
  gem 'octokit', '~> 6.1', require: false
end
