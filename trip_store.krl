ruleset trip_store {
  meta {
    name "Trip Store"
    author "Cameron Hymas"
    logging on
    use module track_trips2
    provides trip, long_trips, short_trips
    shares __testing, trips, long_trips, short_trips
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
      ent:all_trips.filter(function(v, k){v.mileage < track_trips2:long_trip})
    }

    empty_trips = { }
  }

  rule get_trips {
    select when car get_trips

    trips()
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
      time = event:attr("timestamp")
      passed_mileage = event:attr("mileage")
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
      time = event:attr("timestamp")
      passed_mileage = event:attr("mileage")
    }
    send_directive("collect_long_trips") with
      timestamp = time
      mileage = passed_mileage
    always{
      ent:only_long_trips := ent:only_long_trips.defaultsTo(empty_trips, "initializing");
      ent:only_long_trips{[time, "mileage"]} := passed_mileage
    }
  }



  rule gather_trip_data {
    select when car gather_trip_data

    pre {
      name = event:attrs{"name"}.klog("name in track_trips gather_trip_data: ")
      rcn = event:attrs("rcn")
      reply_to_eci = event:attrs("eci")
      trips = trips().klog("TRIPS: ")
    }

    event:send(
      { "eci": reply_to_eci.klog("eci stuff"), "eid": "gather_report",
        "domain": "car", "type": "gather_report",
        "attrs": { "name": name,
                   "rcn": rcn,
                   "trips": trips } } )
  }
}