ruleset trip_store {
  meta {
    name "Trip Store"
    author "Cameron Hymas"
    logging on
    shares __testing
  }
  
  global {
    __testing = { "events": [ { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage" ] },
                              { "domain": "hello", "type": "name", "attrs": [ "id", "first_name", "last_name" ] },
                              { "domain": "hello", "type" : "clear" },
                              { "domain": "echo", "type": "hello", "attrs": [ "id" ] } ] 
    }

    clear_name = { "_0": { "name": { "first": "GlaDOS", "last": "" } } }
    trips = { }
  }

  rule hello_world {
    select when echo hello
    pre{      
      id = event:attr("id").defaultsTo("_0")
      first = ent:name{[id,"name","first"]}
      last = ent:name{[id,"name","last"]}
      name = first + " " + last
    }
    send_directive("say") with
      something = "Hello " + name
  }


  rule clear_names {
    select when hello clear
    always {
      ent:name := clear_name
    }
  }

  rule store_name {
    select when hello name
    pre{
      passed_id = event:attr("id").klog("our passed in id: ")
      passed_first_name = event:attr("first_name").klog("our passed in first_name: ")
      passed_last_name = event:attr("last_name").klog("our passed in last_name: ")
    }
    send_directive("store_name") with
      id = passed_id
      first_name = passed_first_name
      last_name = passed_last_name
    always{
      ent:name := ent:name.defaultsTo(clear_name,"initialization was needed");
      ent:name{[passed_id,"name","first"]} := passed_first_name;
      ent:name{[passed_id,"name","last"]} := passed_last_name
    }
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