# frozen_string_literal: true

module Legion
  module Extensions
    module Bias
      module Helpers
        class BiasStore
          def initialize
            @events  = []
            @anchors = {} # domain -> array of { value:, influence:, recorded_at: }
          end

          def record(event)
            @events << event
            @events.shift while @events.size > Constants::MAX_BIAS_EVENTS
            event
          end

          def recent(count = 10)
            @events.last(count).map(&:to_h)
          end

          def by_type(bias_type)
            @events.select { |e| e.bias_type == bias_type }.map(&:to_h)
          end

          def by_domain(domain)
            @events.select { |e| e.domain == domain }.map(&:to_h)
          end

          def register_anchor(domain, value:, influence: 1.0)
            @anchors[domain] ||= []
            @anchors[domain] << { value: value, influence: influence, recorded_at: Time.now.utc }
            @anchors[domain].shift while @anchors[domain].size > Constants::MAX_ANCHORS
          end

          def anchors_for(domain)
            @anchors.fetch(domain, [])
          end

          def decay_anchors
            @anchors.each_value do |anchor_list|
              anchor_list.each { |a| a[:influence] = (a[:influence] - Constants::ANCHOR_DECAY).clamp(0.0, 1.0) }
              anchor_list.reject! { |a| a[:influence] <= 0.0 }
            end
          end

          def stats
            return { total: 0, by_type: {}, by_domain: {} } if @events.empty?

            by_type = Constants::BIAS_TYPES.to_h do |bt|
              events = @events.select { |e| e.bias_type == bt }
              avg_mag = events.empty? ? 0.0 : events.sum(&:magnitude) / events.size
              [bt, { count: events.size, avg_magnitude: avg_mag.round(4) }]
            end

            domains = @events.map(&:domain).uniq
            by_domain = domains.to_h do |d|
              events = @events.select { |e| e.domain == d }
              [d, { count: events.size }]
            end

            {
              total:     @events.size,
              by_type:   by_type,
              by_domain: by_domain
            }
          end

          def to_h
            {
              total_events:   @events.size,
              anchor_domains: @anchors.keys
            }
          end
        end
      end
    end
  end
end
