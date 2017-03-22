ruleset track_trips2 {
  meta {
    name "Track Trips2"
    author "Cameron Hymas"
    logging on
    shares __testing, long_trip
  }
  
  global {
    __testing = { "events": [ { "domain": "car", "type": "new_trip", "attrs": [ "mileage" ] },
                              { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage" ] } ] 
    }

    long_trip = 200
  }
  
  rule process_trip {
    select when car new_trip mileage re#(.*)# setting(mileage);
    send_directive("trip") with
    trip_length = mileage
    always {
      raise explicit event "trip_processed" attributes event:attrs()
    }
  }

  rule find_long_trips {
    select when explicit trip_processed mileage re#(.*)# setting(mileage);
    fired{
      raise explicit event "found_long_trip"
      with mileage = mileage
      if(mileage > long_trip)        
    }
  }
}