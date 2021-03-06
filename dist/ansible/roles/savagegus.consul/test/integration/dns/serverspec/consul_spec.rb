require 'spec_helper'

describe 'Consul' do
  describe service('consul') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/etc/consul.conf') do
    it { should be_file }
    its(:content) { should match /"dns": 8200/ }
  end
end