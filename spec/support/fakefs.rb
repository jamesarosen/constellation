require 'fakefs/safe'

RSpec.configure do |c|
  c.before(:each) { FakeFS.activate! }
  c.after(:each)  { FakeFS.deactivate! }
end