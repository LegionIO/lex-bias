# frozen_string_literal: true

module Legion
  module Extensions
    module Bias
      module Runners
        module Bias
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def check_for_bias(domain:, decision_context: {}, **)
            Legion::Logging.debug "[bias] check_for_bias domain=#{domain}"
            detected = collect_bias_detections(domain, decision_context)
            active   = detected.select { |b| b[:magnitude] >= Helpers::Constants::DETECTION_THRESHOLD }
            Legion::Logging.debug "[bias] check_for_bias domain=#{domain} detected=#{active.size}"
            { success: true, domain: domain, detected: active, all: detected }
          end

          def record_anchor(domain:, value:, **)
            bias_store.register_anchor(domain, value: value)
            Legion::Logging.debug "[bias] anchor recorded domain=#{domain} value=#{value}"
            { success: true, domain: domain, value: value }
          end

          def update_bias(**)
            bias_store.decay_anchors
            Legion::Logging.debug '[bias] update_bias: anchors decayed'
            { success: true }
          end

          def bias_report(domain: nil, **)
            events = domain ? bias_store.by_domain(domain) : bias_store.recent(50)
            Legion::Logging.debug "[bias] bias_report domain=#{domain.inspect} events=#{events.size}"
            { success: true, domain: domain, events: events, count: events.size }
          end

          def susceptibility_profile(**)
            profile = bias_detector.to_h
            Legion::Logging.debug '[bias] susceptibility_profile'
            { success: true, **profile }
          end

          def bias_stats(**)
            stats = bias_store.stats
            Legion::Logging.debug "[bias] bias_stats total=#{stats[:total]}"
            { success: true, **stats }
          end

          private

          def bias_detector
            @bias_detector ||= Helpers::BiasDetector.new
          end

          def bias_store
            @bias_store ||= Helpers::BiasStore.new
          end

          def collect_bias_detections(domain, ctx)
            results = []
            results.concat(detect_anchoring_bias(domain, ctx))
            results.concat(detect_confirmation_bias(domain, ctx))
            results.concat(detect_availability_bias(domain, ctx))
            results.concat(detect_recency_bias(domain, ctx))
            results.concat(detect_sunk_cost_bias(domain, ctx))
            results
          end

          def detect_anchoring_bias(domain, ctx)
            anchors = bias_store.anchors_for(domain)
            return [] unless anchors.any? && ctx[:current_value]

            anchor_value = anchors.max_by { |a| a[:influence] }&.dig(:value)
            return [] unless anchor_value

            mag = bias_detector.detect_anchoring(
              current_value: ctx[:current_value],
              anchor_value:  anchor_value,
              domain:        domain
            )
            [build_bias_result(:anchoring, domain, mag, ctx)]
          end

          def detect_confirmation_bias(domain, ctx)
            return [] unless ctx[:evidence_direction] && ctx[:hypothesis_direction]

            mag = bias_detector.detect_confirmation(
              evidence_direction:   ctx[:evidence_direction],
              hypothesis_direction: ctx[:hypothesis_direction],
              domain:               domain
            )
            [build_bias_result(:confirmation, domain, mag, ctx)]
          end

          def detect_availability_bias(domain, ctx)
            return [] unless ctx[:recent_events]

            mag = bias_detector.detect_availability(recent_events: ctx[:recent_events], domain: domain)
            [build_bias_result(:availability, domain, mag, ctx)]
          end

          def detect_recency_bias(domain, ctx)
            return [] unless ctx[:data_points]

            mag = bias_detector.detect_recency(data_points: ctx[:data_points], domain: domain)
            [build_bias_result(:recency, domain, mag, ctx)]
          end

          def detect_sunk_cost_bias(domain, ctx)
            return [] unless ctx[:invested] && !ctx[:expected_return].nil?

            mag = bias_detector.detect_sunk_cost(
              invested:        ctx[:invested],
              expected_return: ctx[:expected_return],
              domain:          domain
            )
            [build_bias_result(:sunk_cost, domain, mag, ctx)]
          end

          def build_bias_result(bias_type, domain, magnitude, context)
            correction = bias_detector.correction_for(magnitude)
            corrected  = magnitude >= Helpers::Constants::DETECTION_THRESHOLD

            if corrected
              event = Helpers::BiasEvent.new(
                bias_type:          bias_type,
                domain:             domain,
                magnitude:          magnitude,
                corrected:          corrected,
                correction_applied: correction,
                context:            context
              )
              bias_store.record(event)
            end

            {
              bias_type:          bias_type,
              magnitude:          magnitude,
              corrected:          corrected,
              correction_applied: correction
            }
          end
        end
      end
    end
  end
end
