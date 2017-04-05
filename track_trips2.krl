ruleset track_trips2 {
  meta {
    name "Track Trips2"
    author "Cameron Hymas"
    logging on
    provides long_trip
    shares __testing, long_trip
  }
  
  global {
    __testing = { "events": [ { "domain": "car", "type": "new_trip", "attrs": [ "mileage" ] },
                              { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage", "timestamp" ] } ] 
    }

    long_trip = 200
  }
  
  rule process_trip {
    select when car new_trip mileage re#(.*)# setting(mileage);
    pre {
      time = time:now()
    }
    send_directive("trip") with
    trip_length = mileage
    timestamp = time
    always {
      raise explicit event "trip_processed" 
      with mileage = mileage
      timestamp = time
    }
  }

  rule find_long_trips {
    select when explicit trip_processed mileage re#(.*)# setting(mileage);
    pre {
      time = event:attr("timestamp")
    }
    fired{
      raise explicit event "found_long_trip"
      with mileage = mileage
      timestamp = time
      if(mileage > long_trip)        
    }
  }


  rule gather_trip_data{
    select when car gather_trip_data

    pre {
      name = event:attrs("name").klog("name in track_trips gather_trip_data: ")
      rcn = event:attrs("rcn")
      reply_to_eci = event:attrs("eci")
      trips = http:get("http://localhost:8080/sky/cloud/" + meta:eci + "/trip_store/trips"){["content"]}.decode()
      otherTrips = trips.klog("TRIPS: ")
    }

    event:send(
      { "eci": reply_to_eci, "eid": "gather_report",
        "domain": "car", "type": "gather_report",
        "attrs": { "name": name,
                   "rcn": rcn,
                   "trips": trips.klog("gather_trip_data trips: ") } } )
  }
}



