require 'uri'
require 'libwebsocket'

module EventMachine
  class WebSocketClient < Connection
    include Deferrable

    attr_accessor :url

    def self.connect uri
      p_uri = URI.parse(uri)
      conn = EM.connect(p_uri.host, p_uri.port || 80, self) do |c|
        c.url = uri
      end
    end

    def post_init
      @handshaked = false
      @frame  = LibWebSocket::Frame.new
    end

    def connection_completed
      @hs = LibWebSocket::OpeningHandshake::Client.new(:url => @url)
      send_data @hs.to_s
    end

    def stream &cb; @stream = cb; end
    def disconnect &cb; @disconnect = cb; end
    
    def receive_data data
      if !@handshaked
        result = @hs.parse data
        fail @hs.error unless result
        
        if @hs.done?
          @handshaked = true
          succeed
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
