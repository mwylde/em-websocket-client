# em-websocket-client

This gem implements a simple websocket client inside EventMachine.
This might be useful for testing web socket servers or consuming
WebSocket APIs. In particular it supports the
[hixie-76](http://tools.ietf.org/html/draft-hixie-thewebsocketprotocol-76)
version of the protocol, which is also implemented in Chrome and
Safari. At this time, the wss (WebSocket over SSL) protocol is not
supported.

Using the library is simple:

```ruby
require 'em-websocket-client'

EM.run do
  conn = EventMachine::WebSocketClient.connect("ws://echo.websocket.org/")

  conn.callback do
    conn.send_msg "Hello!"
    conn.send_msg "done"
  end

  conn.errback do |e|
    puts "Got error: #{e}"
  end
  
  conn.stream do |msg|
    puts "<#{msg}>"
    if msg == "done"
      conn.close_connection
    end
  end

  conn.disconnect do
    puts "gone"
    EM::stop_event_loop
  end
end

# prints out:
# <Hello!>
# <done>
# gone
```
