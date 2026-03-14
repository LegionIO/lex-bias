# frozen_string_literal: true

module Legion
  module Extensions
    module Bias
      module Helpers
        module Constants
          BIAS_TYPES = %i[anchoring confirmation availability recency sunk_cost].freeze

          DETECTION_THRESHOLD          = 0.3   # above this = bias likely influencing decision
          CORRECTION_FACTOR            = 0.5   # how much to correct when bias detected
          DEFAULT_SUSCEPTIBILITY       = 0.5   # starting susceptibility per bias
          SUSCEPTIBILITY_ALPHA         = 0.1   # EMA alpha for updating susceptibility
          DECAY_RATE                   = 0.02  # how fast bias activation decays per tick
          MAX_BIAS_EVENTS              = 200   # max tracked bias events
          MAX_ANCHORS                  = 50    # max tracked anchor values
          ANCHOR_DECAY                 = 0.05  # how fast anchor influence decays
          CONFIRMATION_WEIGHT          = 0.7   # weight of confirming vs disconfirming evidence
          AVAILABILITY_RECENCY_WINDOW  = 10    # recent events window for availability heuristic
        end
      end
    end
  end
end
