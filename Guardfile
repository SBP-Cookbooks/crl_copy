guard :rspec, cmd: 'chef exec rspec', all_on_start: false do
  watch(%r{^spec/unit/*/(.+)_spec\.rb$})
  watch(%r{^recipes/(.+)\.rb$}) { |m| "spec/unit/recipes/#{m[1]}_spec.rb" }
  watch(%r{^resources/(.+)\.rb$}) { |_m| 'spec/unit/recipes/default_spec.rb' }
  watch(%r{^templates/default/(.+)\.erb$}) { |_m| 'spec/unit/recipes/default_spec.rb' }
end
