module PMOG
  class PMOGError < StandardError
    @msg = nil

    def initialize(message = nil)
      @msg = message
    end

    def message
      if @msg.nil?
        return default
      else
        return @msg
      end
    end

    def default; end
  end
end

module Exceptions
  class MissionCompleteError < PMOG::PMOGError; end
end