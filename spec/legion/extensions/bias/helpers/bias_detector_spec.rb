# frozen_string_literal: true

require 'legion/extensions/bias/helpers/constants'
require 'legion/extensions/bias/helpers/bias_detector'

RSpec.describe Legion::Extensions::Bias::Helpers::BiasDetector do
  subject(:detector) { described_class.new }

  describe '#susceptibility_for' do
    it 'returns DEFAULT_SUSCEPTIBILITY for all bias types at init' do
      Legion::Extensions::Bias::Helpers::Constants::BIAS_TYPES.each do |bt|
        expect(detector.susceptibility_for(bt)).to eq(
          Legion::Extensions::Bias::Helpers::Constants::DEFAULT_SUSCEPTIBILITY
        )
      end
    end
  end

  describe '#detect_anchoring' do
    it 'returns high magnitude when current value is very close to anchor' do
      mag = detector.detect_anchoring(current_value: 100.0, anchor_value: 100.0)
      expect(mag).to be_within(0.01).of(0.5) # pull=1.0 * susceptibility=0.5
    end

    it 'returns low magnitude when current value is far from anchor' do
      mag = detector.detect_anchoring(current_value: 200.0, anchor_value: 100.0)
      expect(mag).to be < 0.3
    end

    it 'returns 0.0 when anchor_value is zero' do
      mag = detector.detect_anchoring(current_value: 50.0, anchor_value: 0.0)
      expect(mag).to eq(0.0)
    end

    it 'returns 0.0 when anchor_value is nil' do
      mag = detector.detect_anchoring(current_value: 50.0, anchor_value: nil)
      expect(mag).to eq(0.0)
    end

    it 'clamps result to [0, 1]' do
      mag = detector.detect_anchoring(current_value: 100.0, anchor_value: 100.0)
      expect(mag).to be_between(0.0, 1.0)
    end
  end

  describe '#detect_confirmation' do
    it 'returns higher magnitude when evidence matches hypothesis' do
      mag_match = detector.detect_confirmation(
        evidence_direction:   :positive,
        hypothesis_direction: :positive
      )
      mag_mismatch = detector.detect_confirmation(
        evidence_direction:   :negative,
        hypothesis_direction: :positive
      )
      expect(mag_match).to be > mag_mismatch
    end

    it 'returns magnitude >= CONFIRMATION_WEIGHT * susceptibility when matching' do
      mag = detector.detect_confirmation(
        evidence_direction:   :up,
        hypothesis_direction: :up
      )
      expected = Legion::Extensions::Bias::Helpers::Constants::CONFIRMATION_WEIGHT *
                 Legion::Extensions::Bias::Helpers::Constants::DEFAULT_SUSCEPTIBILITY
      expect(mag).to be_within(0.001).of(expected)
    end
  end

  describe '#detect_availability' do
    it 'returns higher magnitude with more recent events' do
      mag_full = detector.detect_availability(recent_events: Array.new(10, :event))
      mag_none = detector.detect_availability(recent_events: [])
      expect(mag_full).to be > mag_none
    end

    it 'returns 0 with empty recent_events' do
      mag = detector.detect_availability(recent_events: [])
      expect(mag).to eq(0.0)
    end
  end

  describe '#detect_recency' do
    it 'returns 0 with fewer than 2 data points' do
      mag = detector.detect_recency(data_points: [1.0])
      expect(mag).to eq(0.0)
    end

    it 'returns 0 when all values are equal (zero range)' do
      mag = detector.detect_recency(data_points: [5.0, 5.0, 5.0, 5.0])
      expect(mag).to eq(0.0)
    end

    it 'returns higher magnitude when recent half differs significantly from earlier half' do
      early = [1.0, 1.0, 1.0, 1.0]
      recent = [9.0, 9.0, 9.0, 9.0]
      mag = detector.detect_recency(data_points: early + recent)
      expect(mag).to be > 0.3
    end
  end

  describe '#detect_sunk_cost' do
    it 'returns 0 when invested is 0' do
      mag = detector.detect_sunk_cost(invested: 0, expected_return: 100)
      expect(mag).to eq(0.0)
    end

    it 'returns higher magnitude with large investment and low expected return' do
      mag = detector.detect_sunk_cost(invested: 1_000_000, expected_return: 1)
      expect(mag).to be > 0.3
    end

    it 'returns lower magnitude with small investment and large expected return' do
      mag = detector.detect_sunk_cost(invested: 1, expected_return: 1_000_000)
      expect(mag).to be < 0.1
    end
  end

  describe '#correction_for' do
    it 'applies CORRECTION_FACTOR to magnitude' do
      result = detector.correction_for(0.6)
      expect(result).to be_within(0.001).of(
        0.6 * Legion::Extensions::Bias::Helpers::Constants::CORRECTION_FACTOR
      )
    end

    it 'clamps to [0, 1]' do
      expect(detector.correction_for(2.0)).to eq(1.0)
      expect(detector.correction_for(-1.0)).to eq(0.0)
    end
  end

  describe '#update_susceptibility' do
    it 'increases susceptibility toward 1.0 when repeatedly detected' do
      initial = detector.susceptibility_for(:anchoring)
      10.times { detector.update_susceptibility(:anchoring, detected: true) }
      expect(detector.susceptibility_for(:anchoring)).to be > initial
    end

    it 'decreases susceptibility toward 0.0 when not detected' do
      initial = detector.susceptibility_for(:anchoring)
      10.times { detector.update_susceptibility(:anchoring, detected: false) }
      expect(detector.susceptibility_for(:anchoring)).to be < initial
    end

    it 'ignores unknown bias types' do
      expect { detector.update_susceptibility(:unknown_bias, detected: true) }.not_to raise_error
    end
  end

  describe '#to_h' do
    it 'returns susceptibility hash' do
      h = detector.to_h
      expect(h[:susceptibility]).to be_a(Hash)
      expect(h[:susceptibility].keys).to match_array(
        Legion::Extensions::Bias::Helpers::Constants::BIAS_TYPES
      )
    end
  end
end
