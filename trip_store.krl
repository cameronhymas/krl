ruleset trip_store {
  meta {
    name "Trip Store"
    author "Cameron Hymas"
    logging on
    shares __testing
  }
  
  global {
    __testing = { "events": [ { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage" ] },
                              { "domain": "explicit", "type": "found_long_trip", "attrs": [ "mileage" ] },
                              { "domain": "explicit", "type" : "clear" } ] 
    }

    empty_trips = { }
  }


  rule clear_trips {
    select when explicit clear
    always {
      ent:trips := empty_trips;
      ent:long_trips := empty_trips
    }
  }

  
  rule collect_trips {
    select when explicit trip_processed 
    pre {
      time = time:now()
      passed_mileage = event:attr("mileage").klog("our passed in mileage: ")
    }
    send_directive("collect_trips") with
      timestamp = time
      mileage = passed_mileage
    always{
      ent:trips := ent:trips.defaultsTo(empty_trips, "initializing");
      ent:trips{[time, "mileage"]} := passed_mileage
    }
  }


  rule collect_long_trips {
    select when explicit found_long_trip 
    pre {
      time = time:now()
      passed_mileage = event:attr("mileage").klog("our passed in mileage: ")
    }
    send_directive("collect_long_trips") with
      timestamp = time
      mileage = passed_mileage
    always{
      ent:long_trips := ent:long_trips.defaultsTo(empty_trips, "initializing");
      ent:long_trips{[time, "mileage"]} := passed_mileage
    }
  }
}