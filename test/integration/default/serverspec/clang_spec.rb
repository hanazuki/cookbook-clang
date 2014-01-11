require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin'
  end
end

%w[clang clang++].each do |prog|
  describe file("/usr/local/bin/#{prog}") do
    it { should be_executable }
  end
end
