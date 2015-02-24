require 'eventmachine'
require_relative 'hatch_server'

Plugin.create(:hatch) do
  @main = Thread.new {
    @server = EventMachine.run {
      EventMachine.start_server "127.0.0.1", 3939, HatchServer
    }
  }

  on_destroy do
    @main.instance_eval {
      EventMachine.stop_server @server
    }
    @main.stop
  end
end
