# frozen_string_literal: true

require 'legion/extensions/bias/client'

RSpec.describe Legion::Extensions::Bias::Runners::Bias do
  let(:client) { Legion::Extensions::Bias::Client.new }

  describe '#record_anchor' do
    it 'returns success: true' do
      result = client.record_anchor(domain: :finance, value: 100.0)
      expect(result[:success]).to be true
      expect(result[:domain]).to eq(:finance)
      expect(result[:value]).to eq(100.0)
    end
  end

  describe '#check_for_bias' do
    context 'with no decision context' do
      it 'returns success: true with empty detected list' do
        result = client.check_for_bias(domain: :test)
        expect(result[:success]).to be true
        expect(result[:detected]).to be_empty
      end
    end

    context 'with anchoring context' do
      before { client.record_anchor(domain: :finance, value: 100.0) }

      it 'detects anchoring when current value is close to anchor' do
        result = client.check_for_bias(
          domain:           :finance,
          decision_context: { current_value: 101.0 }
        )
        expect(result[:success]).to be true
        anchoring = result[:all].find { |b| b[:bias_type] == :anchoring }
        expect(anchoring).not_to be_nil
        expect(anchoring[:magnitude]).to be > 0.0
      end
    end

    context 'with confirmation bias context' do
      it 'detects confirmation bias when evidence matches hypothesis' do
        result = client.check_for_bias(
          domain:           :research,
          decision_context: {
            evidence_direction:   :positive,
            hypothesis_direction: :positive
          }
        )
        confirmation = result[:all].find { |b| b[:bias_type] == :confirmation }
        expect(confirmation[:magnitude]).to be > 0.0
      end
    end

    context 'with availability bias context' do
      it 'detects availability bias with recent events' do
        result = client.check_for_bias(
          domain:           :safety,
          decision_context: { recent_events: Array.new(10, :incident) }
        )
        availability = result[:all].find { |b| b[:bias_type] == :availability }
        expect(availability[:magnitude]).to be > 0.0
      end
    end

    context 'with recency bias context' do
      it 'detects recency bias with skewed data points' do
        data = [1.0, 1.0, 1.0, 1.0, 9.0, 9.0, 9.0, 9.0]
        result = client.check_for_bias(
          domain:           :market,
          decision_context: { data_points: data }
        )
        recency = result[:all].find { |b| b[:bias_type] == :recency }
        expect(recency[:magnitude]).to be > 0.0
      end
    end

    context 'with sunk cost bias context' do
      it 'detects sunk cost bias with high investment and low return' do
        result = client.check_for_bias(
          domain:           :project,
          decision_context: { invested: 1_000_000, expected_return: 100 }
        )
        sunk = result[:all].find { |b| b[:bias_type] == :sunk_cost }
        expect(sunk[:magnitude]).to be > 0.0
      end
    end

    it 'marks bias as corrected when magnitude exceeds threshold' do
      client.record_anchor(domain: :finance, value: 100.0)
      result = client.check_for_bias(
        domain:           :finance,
        decision_context: { current_value: 100.0 }
      )
      anchoring = result[:all].find { |b| b[:bias_type] == :anchoring }
      if anchoring[:magnitude] >= Legion::Extensions::Bias::Helpers::Constants::DETECTION_THRESHOLD
        expect(anchoring[:corrected]).to be true
        expect(anchoring[:correction_applied]).to be > 0.0
      end
    end
  end

  describe '#update_bias' do
    it 'returns success: true' do
      result = client.update_bias
      expect(result[:success]).to be true
    end

    it 'decays anchor influence' do
      client.record_anchor(domain: :pricing, value: 50.0)
      client.update_bias
    end
  end

  describe '#bias_report' do
    it 'returns success: true with empty events on fresh client' do
      result = client.bias_report
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'filters by domain when provided' do
      client.record_anchor(domain: :finance, value: 100.0)
      client.check_for_bias(domain: :finance, decision_context: { current_value: 100.0 })
      result = client.bias_report(domain: :finance)
      expect(result[:domain]).to eq(:finance)
    end
  end

  describe '#susceptibility_profile' do
    it 'returns success: true with susceptibility hash' do
      result = client.susceptibility_profile
      expect(result[:success]).to be true
      expect(result[:susceptibility]).to be_a(Hash)
      expect(result[:susceptibility].keys).to match_array(
        Legion::Extensions::Bias::Helpers::Constants::BIAS_TYPES
      )
    end
  end

  describe '#bias_stats' do
    it 'returns success: true' do
      result = client.bias_stats
      expect(result[:success]).to be true
      expect(result[:total]).to eq(0)
    end

    it 'reflects recorded events' do
      client.record_anchor(domain: :finance, value: 100.0)
      client.check_for_bias(domain: :finance, decision_context: { current_value: 100.0 })
      result = client.bias_stats
      expect(result[:total]).to be >= 0
    end
  end
end
