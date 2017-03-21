ruleset echo_server {
  meta {
    name "Echo Server"
    description <<
A first ruleset for the Quickstart
>>
    author "Phil Windley"
    logging on
    shares __testing
  }
  
  global {
    __testing = { "events": [ { "domain": "echo", "type": "hello" },
                              { "domain": "echo", "type": "message", "attrs": [ "input" ] } ] 
    }
  }
  
  rule hello_world {
    select when echo hello
    send_directive("say") with
    something = "Hello World"
  }
  rule echo is active {
    select when echo message input re#(.*)# setting(m);
    send_directive("say") with
    something = m
  }
}