Gem::Specification.new do |s|
  s.name = 'logstash-filter-referer'
  s.version = '0.1'
  s.licenses = ['Apache License (2.0)']
  s.summary = "Build information about referer"
  s.description = ""
  s.authors = ["athoune"]
  s.email = 'mathieu@garambrogne.net'
  s.homepage = "http://bearstech.com/"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", ">= 2.0.0", "< 3.0.0"
  s.add_development_dependency 'logstash-devutils'
end
