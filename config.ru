# frozen_string_literal: true

require_relative "config/environment"

class GVLInstrumentationMiddleware
  def initialize(app)
    GVLTools::LocalTimer.enable
    @app = app
  end

  def call(env)
    gvl_before = GVLTools::LocalTimer.monotonic_time
    time_before = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)

    response = @app.call(env)
    gvl_wait_ms = (GVLTools::LocalTimer.monotonic_time - gvl_before) / 1_000_000.0
    duration_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - time_before

    Rails.logger.info("[#{env["action_dispatch.request_id"]}] [GVLTools] rack_response_time=#{duration_ms.round(2)}ms gvl_wait_time=#{gvl_wait_ms.round(2)}ms")

    response
  end
end

use GVLInstrumentationMiddleware
run Rails.application
Rails.application.load_server
