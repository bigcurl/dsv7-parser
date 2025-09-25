# frozen_string_literal: true

require_relative 'types/common'
require_relative 'types/datetime'
require_relative 'types/enums1'
require_relative 'types/enums2'

module Dsv7
  class Validator
    module WkTypeChecks
      include WkTypeChecksCommon
      include WkTypeChecksDateTime
      include WkTypeChecksEnums1
      include WkTypeChecksEnums2
    end
  end
end
