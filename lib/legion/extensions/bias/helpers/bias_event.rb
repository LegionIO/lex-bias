# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Bias
      module Helpers
        class BiasEvent
          attr_reader :id, :bias_type, :domain, :magnitude, :corrected,
                      :correction_applied, :context, :timestamp

          def initialize(bias_type:, domain:, magnitude:, **opts)
            @id                 = SecureRandom.uuid
            @bias_type          = bias_type
            @domain             = domain
            @magnitude          = magnitude
            @corrected          = opts.fetch(:corrected, false)
            @correction_applied = opts.fetch(:correction_applied, 0.0)
            @context            = opts.fetch(:context, {})
            @timestamp          = Time.now.utc
          end

          def to_h
            {
              id:                 @id,
              bias_type:          @bias_type,
              domain:             @domain,
              magnitude:          @magnitude,
              corrected:          @corrected,
              correction_applied: @correction_applied,
              context:            @context,
              timestamp:          @timestamp
            }
          end
        end
      end
    end
  end
end
