# frozen_string_literal: true

# Aggregates type‑check mixins used by schemas.
#
# Each `check_<type>(name, index, value, line_number, opts)` method is
# expected to either accept the value or call `add_error(message)` on the
# including schema to record a validation error with context.

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
