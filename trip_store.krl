ruleset trip_store {
  meta {
    name "Trip Store"
    author "Cameron Hymas"
    logging on
    provides trip, long_trips, short_trips
    sharing on
  }
  
  global {
    __testing = { "events": [ { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage" ] },
                              { "domain": "explicit", "type": "found_long_trip", "attrs": [ "mileage" ] },
                              { "domain": "car", "type" : "reset" } ] 
    }

    trips = function(){
      ent:all_trips
    }

    long_trips = function(){
      ent:only_long_trips
    }

    short_trips = function() {
      ent:all_trips.difference(ent:all_long_trips)
    }

    empty_trips = { }
  }


  rule clear_trips {
    select when car reset
    always {
      ent:all_trips := empty_trips;
      ent:only_long_trips := empty_trips
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
      ent:all_trips := ent:all_trips.defaultsTo(empty_trips, "initializing");
      ent:all_trips{[time, "mileage"]} := passed_mileage
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
      ent:only_long_trips := ent:only_long_trips.defaultsTo(empty_trips, "initializing");
      ent:only_long_trips{[time, "mileage"]} := passed_mileage
    }
  }
}