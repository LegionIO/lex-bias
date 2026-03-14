# frozen_string_literal: true

require 'legion/extensions/bias/client'

RSpec.describe Legion::Extensions::Bias::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:check_for_bias)
    expect(client).to respond_to(:record_anchor)
    expect(client).to respond_to(:update_bias)
    expect(client).to respond_to(:bias_report)
    expect(client).to respond_to(:susceptibility_profile)
    expect(client).to respond_to(:bias_stats)
  end
end
