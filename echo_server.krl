ruleset echo_server {
  meta {
    name "Echo Server"
    author "Cameron Hymas"
    logging on
    shares __testing
  }
  
  global {
    __testing = { "events": [ { "domain": "echo", "type": "hello" },
                              { "domain": "echo", "type": "message", "attrs": [ "input" ] } ] 
    }
  }
  
  rule hello {
    select when echo hello
    send_directive("say") with
    something = "Hello World"
  }
  rule message is active {
    select when echo message input re#(.*)# setting(m);
    send_directive("say") with
    something = m
  }
}