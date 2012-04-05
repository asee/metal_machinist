Gem::Specification.new do |s|
  s.name = 'metal_machinist'
  s.authors = ['ASEE']
  s.summary = 'Supports stackable blueprints'
  s.description = 'This is a pretty sweet mod, but its apparently only compatible with machinist 1.0'
  s.files = ['lib/metal_machinist.rb', 'metal_machinist.gemspec'] #`git ls-files` # `svn -R list`.split("\n")
  s.version = "0.0.1"

  s.add_dependency 'machinist', '1.0.6'
end
