# frozen_string_literal: true

require 'legion/extensions/bias/helpers/constants'
require 'legion/extensions/bias/helpers/bias_event'
require 'legion/extensions/bias/helpers/bias_store'

RSpec.describe Legion::Extensions::Bias::Helpers::BiasStore do
  subject(:store) { described_class.new }

  let(:event) do
    Legion::Extensions::Bias::Helpers::BiasEvent.new(
      bias_type: :anchoring,
      domain:    :finance,
      magnitude: 0.6
    )
  end

  let(:event2) do
    Legion::Extensions::Bias::Helpers::BiasEvent.new(
      bias_type: :confirmation,
      domain:    :research,
      magnitude: 0.4
    )
  end

  describe '#record' do
    it 'stores an event and returns it' do
      result = store.record(event)
      expect(result).to eq(event)
    end

    it 'trims events at MAX_BIAS_EVENTS' do
      max = Legion::Extensions::Bias::Helpers::Constants::MAX_BIAS_EVENTS
      (max + 10).times do
        store.record(Legion::Extensions::Bias::Helpers::BiasEvent.new(
                       bias_type: :recency,
                       domain:    :test,
                       magnitude: 0.1
                     ))
      end
      expect(store.recent(max + 10).size).to eq(max)
    end
  end

  describe '#recent' do
    it 'returns the most recent events as hashes' do
      store.record(event)
      store.record(event2)
      result = store.recent(2)
      expect(result.size).to eq(2)
      expect(result.first).to be_a(Hash)
    end

    it 'returns fewer than requested when not enough events' do
      store.record(event)
      expect(store.recent(10).size).to eq(1)
    end
  end

  describe '#by_type' do
    it 'returns only events matching bias_type' do
      store.record(event)
      store.record(event2)
      result = store.by_type(:anchoring)
      expect(result.size).to eq(1)
      expect(result.first[:bias_type]).to eq(:anchoring)
    end
  end

  describe '#by_domain' do
    it 'returns only events matching domain' do
      store.record(event)
      store.record(event2)
      result = store.by_domain(:finance)
      expect(result.size).to eq(1)
      expect(result.first[:domain]).to eq(:finance)
    end
  end

  describe '#register_anchor and #anchors_for' do
    it 'stores anchor values for a domain' do
      store.register_anchor(:pricing, value: 99.99)
      anchors = store.anchors_for(:pricing)
      expect(anchors.size).to eq(1)
      expect(anchors.first[:value]).to eq(99.99)
    end

    it 'returns empty array for unknown domain' do
      expect(store.anchors_for(:nonexistent)).to eq([])
    end

    it 'trims anchors at MAX_ANCHORS' do
      max = Legion::Extensions::Bias::Helpers::Constants::MAX_ANCHORS
      (max + 5).times { |i| store.register_anchor(:domain, value: i) }
      expect(store.anchors_for(:domain).size).to eq(max)
    end
  end

  describe '#decay_anchors' do
    it 'reduces anchor influence' do
      store.register_anchor(:pricing, value: 100.0, influence: 1.0)
      store.decay_anchors
      anchor = store.anchors_for(:pricing).first
      expect(anchor[:influence]).to be < 1.0
    end

    it 'removes anchors with influence at or below 0' do
      store.register_anchor(:pricing, value: 1.0, influence: 0.01)
      store.decay_anchors
      expect(store.anchors_for(:pricing)).to be_empty
    end
  end

  describe '#stats' do
    it 'returns total 0 with empty store' do
      result = store.stats
      expect(result[:total]).to eq(0)
    end

    it 'aggregates counts and avg_magnitude per type' do
      store.record(event)
      stats = store.stats
      expect(stats[:by_type][:anchoring][:count]).to eq(1)
      expect(stats[:by_type][:anchoring][:avg_magnitude]).to eq(0.6)
    end

    it 'aggregates by domain' do
      store.record(event)
      stats = store.stats
      expect(stats[:by_domain][:finance][:count]).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns total_events and anchor_domains' do
      store.record(event)
      store.register_anchor(:pricing, value: 50.0)
      h = store.to_h
      expect(h[:total_events]).to eq(1)
      expect(h[:anchor_domains]).to include(:pricing)
    end
  end
end
