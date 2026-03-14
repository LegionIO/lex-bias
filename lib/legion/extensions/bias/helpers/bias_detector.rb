# frozen_string_literal: true

module Legion
  module Extensions
    module Bias
      module Helpers
        class BiasDetector
          include Constants

          def initialize
            @susceptibility = Constants::BIAS_TYPES.to_h { |b| [b, Constants::DEFAULT_SUSCEPTIBILITY] }
          end

          def detect_anchoring(current_value:, anchor_value:, domain: nil) # rubocop:disable Lint/UnusedMethodArgument
            return 0.0 if anchor_value.nil? || anchor_value.zero?

            distance = (current_value - anchor_value).abs.to_f / anchor_value.abs
            pull      = 1.0 - distance.clamp(0.0, 1.0)
            magnitude = pull * susceptibility_for(:anchoring)
            update_susceptibility(:anchoring, detected: magnitude >= Constants::DETECTION_THRESHOLD)
            magnitude.clamp(0.0, 1.0)
          end

          def detect_confirmation(evidence_direction:, hypothesis_direction:, domain: nil) # rubocop:disable Lint/UnusedMethodArgument
            magnitude = if evidence_direction == hypothesis_direction
                          Constants::CONFIRMATION_WEIGHT * susceptibility_for(:confirmation)
                        else
                          (1.0 - Constants::CONFIRMATION_WEIGHT) * susceptibility_for(:confirmation)
                        end
            update_susceptibility(:confirmation, detected: magnitude >= Constants::DETECTION_THRESHOLD)
            magnitude.clamp(0.0, 1.0)
          end

          def detect_availability(recent_events:, domain: nil) # rubocop:disable Lint/UnusedMethodArgument
            window    = Constants::AVAILABILITY_RECENCY_WINDOW
            density   = [recent_events.size, window].min.to_f / window
            magnitude = density * susceptibility_for(:availability)
            update_susceptibility(:availability, detected: magnitude >= Constants::DETECTION_THRESHOLD)
            magnitude.clamp(0.0, 1.0)
          end

          def detect_recency(data_points:, domain: nil) # rubocop:disable Lint/UnusedMethodArgument
            return 0.0 if data_points.size < 2

            total = data_points.size
            half  = total / 2
            recent_half  = data_points.last(half)
            earlier_half = data_points.first(half)

            recent_mean  = mean(recent_half)
            earlier_mean = mean(earlier_half)

            range = (data_points.max - data_points.min).to_f
            return 0.0 if range.zero?

            skew      = (recent_mean - earlier_mean).abs / range
            magnitude = skew * susceptibility_for(:recency)
            update_susceptibility(:recency, detected: magnitude >= Constants::DETECTION_THRESHOLD)
            magnitude.clamp(0.0, 1.0)
          end

          def detect_sunk_cost(invested:, expected_return:, domain: nil) # rubocop:disable Lint/UnusedMethodArgument
            return 0.0 if invested <= 0

            ratio     = invested.to_f / (invested + expected_return.abs + 1.0)
            magnitude = ratio * susceptibility_for(:sunk_cost)
            update_susceptibility(:sunk_cost, detected: magnitude >= Constants::DETECTION_THRESHOLD)
            magnitude.clamp(0.0, 1.0)
          end

          def susceptibility_for(bias_type)
            @susceptibility.fetch(bias_type, Constants::DEFAULT_SUSCEPTIBILITY)
          end

          def update_susceptibility(bias_type, detected:)
            return unless @susceptibility.key?(bias_type)

            alpha   = Constants::SUSCEPTIBILITY_ALPHA
            signal  = detected ? 1.0 : 0.0
            current = @susceptibility[bias_type]
            @susceptibility[bias_type] = ((alpha * signal) + ((1.0 - alpha) * current)).clamp(0.0, 1.0)
          end

          def correction_for(magnitude)
            (magnitude * Constants::CORRECTION_FACTOR).clamp(0.0, 1.0)
          end

          def to_h
            { susceptibility: @susceptibility.dup }
          end

          private

          def mean(values)
            return 0.0 if values.empty?

            values.sum.to_f / values.size
          end
        end
      end
    end
  end
end
