module HatchServer
  def post_init
    send_data "Welcome to underground...\n"
    @context = Object.new
  end

  def receive_data(data)
    begin
      result = @context.instance_eval(data)
      send_data "=> #{result.to_s}\n"
    rescue Exception => e
      send_data "Exception: #{e}\n"
      send_data "#{e.backtrace.join("\n")}\n"
    end
  end
end
