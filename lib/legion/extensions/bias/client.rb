# frozen_string_literal: true

require 'legion/extensions/bias/helpers/constants'
require 'legion/extensions/bias/helpers/bias_event'
require 'legion/extensions/bias/helpers/bias_detector'
require 'legion/extensions/bias/helpers/bias_store'
require 'legion/extensions/bias/runners/bias'

module Legion
  module Extensions
    module Bias
      class Client
        include Runners::Bias

        def initialize(**)
          @bias_detector = Helpers::BiasDetector.new
          @bias_store    = Helpers::BiasStore.new
        end

        private

        attr_reader :bias_detector, :bias_store
      end
    end
  end
end
