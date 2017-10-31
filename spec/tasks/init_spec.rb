require_relative '../../tasks/init'

describe MCollective::PuppetTask do
  before(:all) do
    MCollective::Config.instance.loadconfig('/dev/null')
  end

  let(:params) { {} }

  it 'loads tasks' do
    runner = described_class.new(params)
    expect(runner.agents.keys).to eq(['rpcutil'])
  end

  it 'returns an error when the agent isnt found' do
    params = { agent: 'not-a-real-agent' }
    runner = described_class.new(params)
    expect(runner.run_action[:_error][:kind]).to eq('puppetlabs.mco_rpc/unknown-agent')
  end

  it 'returns an error when the action does not exist' do
    params = { agent: 'rpcutil', action: 'not-an-action' }
    runner = described_class.new(params)
    expect(runner.run_action[:_error][:kind]).to eq('puppetlabs.mco_rpc/mco_error')
  end

  it 'returns an error when the args are invalid' do
    params = { agent: 'rpcutil', action: 'get_fact' }
    runner = described_class.new(params)
    expect(runner.run_action[:_error][:kind]).to eq('puppetlabs.mco_rpc/mco_error')
  end
end
