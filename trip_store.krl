ruleset trip_store {
  meta {
    name "Trip Store"
    author "Cameron Hymas"
    logging on
    shares __testing
  }
  
  global {
    __testing = { "events": [ { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage" ] } ] 
    }

    trips = { }
  }
  
  rule collect_trips {
    select when explicit trip_processed 
    pre {
      passed_mileage = event:attr("mileage").klog("our passed in mileage: ")
      time = time:now()
    }
    send_directive("collect_trips") with
      mileage = passed_mileage
      timestamp = time
    always{
      ent:trips{[timestamp, "trip_processed", "mileage"]}
    }
  }
}