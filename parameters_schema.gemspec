Gem::Specification.new do |s|
  s.name        = 'parameters_schema'
  s.version     = '0.42'
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Strict schema for request parameters"
  s.description = "Validates parameters of requests using a JSON schema defined with a simple DSL"
  s.authors     = ['Jodi Giordano']
  s.email       = 'giordano.jodi@gmail.com'
  s.homepage    = 'https://github.com/jodigiordano/parameters_schema'
  s.files       = ['Gemfile', 'Rakefile', 'README.md'] + Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  s.license     = 'MIT'

  s.add_dependency 'activesupport'
end
