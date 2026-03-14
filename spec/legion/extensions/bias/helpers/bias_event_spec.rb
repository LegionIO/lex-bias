# frozen_string_literal: true

require 'legion/extensions/bias/helpers/bias_event'

RSpec.describe Legion::Extensions::Bias::Helpers::BiasEvent do
  let(:event) do
    described_class.new(
      bias_type:          :anchoring,
      domain:             :finance,
      magnitude:          0.6,
      corrected:          true,
      correction_applied: 0.3,
      context:            { current_value: 100 }
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(event.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns bias_type' do
      expect(event.bias_type).to eq(:anchoring)
    end

    it 'assigns domain' do
      expect(event.domain).to eq(:finance)
    end

    it 'assigns magnitude' do
      expect(event.magnitude).to eq(0.6)
    end

    it 'assigns corrected flag' do
      expect(event.corrected).to be true
    end

    it 'assigns correction_applied' do
      expect(event.correction_applied).to eq(0.3)
    end

    it 'assigns context' do
      expect(event.context).to eq({ current_value: 100 })
    end

    it 'sets timestamp to a Time' do
      expect(event.timestamp).to be_a(Time)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = event.to_h
      expect(h[:id]).to eq(event.id)
      expect(h[:bias_type]).to eq(:anchoring)
      expect(h[:domain]).to eq(:finance)
      expect(h[:magnitude]).to eq(0.6)
      expect(h[:corrected]).to be true
      expect(h[:correction_applied]).to eq(0.3)
      expect(h[:context]).to eq({ current_value: 100 })
      expect(h[:timestamp]).to be_a(Time)
    end
  end
end
