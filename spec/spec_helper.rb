require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.platform = 'windows'
end

at_exit { ChefSpec::Coverage.report! }
