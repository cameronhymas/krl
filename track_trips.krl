ruleset track_trips {
  meta {
    name "Track Trips"
    author "Cameron Hymas"
    logging on
    shares __testing
  }
  
  global {
    __testing = { "events": [ { "domain": "echo", "type": "message", "attrs": [ "mileage" ] } ] 
    }
  }
  
  rule process_trip is active {
    select when echo message mileage re#(.*)# setting(mileage);
    send_directive("trip") with
    trip_length = mileage
  }
}