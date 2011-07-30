require 'eventmachine'
require 'uri'
require 'libwebsocket'

module EventMachine
  class WebSocketClient < Connection
    attr_accessor :url

    def self.connect uri, &cb
      p_uri = URI.parse(uri)
      puts p_uri.host
      conn = EM.connect(p_uri.host, 80, self) do |c|
        c.url = uri
        c.callback &cb
      end
      conn
    end

    def post_init
      @handshaked = false
      @frame  = LibWebSocket::Frame.new
    end

    def connection_completed
      @hs = LibWebSocket::OpeningHandshake::Client.new(:url => @url)
      send_data @hs.to_s
    end

    def callback &cb; @callback = cb; end
    def stream &cb; @stream = cb; end
    def disconnect &cb; @disconnect = cb; end
    
    def receive_data data
      if !@handshaked
        @hs.parse data
        if @hs.done?
          @handshaked = true
          @callback.call if @callback
        end
      else
        @frame.append(data)
        while msg = @frame.next
          @stream.call(msg) if @stream
        end
      end
    end

    def send_msg s
      frame = LibWebSocket::Frame.new(s)
      send_data frame.to_s
    end

    def unbind
      super
      @disconnect.call if @disconnect
    end
  end
end
