# frozen_string_literal: true

require 'legion/extensions/bias/version'
require 'legion/extensions/bias/helpers/constants'
require 'legion/extensions/bias/helpers/bias_event'
require 'legion/extensions/bias/helpers/bias_detector'
require 'legion/extensions/bias/helpers/bias_store'
require 'legion/extensions/bias/runners/bias'

module Legion
  module Extensions
    module Bias
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
