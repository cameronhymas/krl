ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    author "Cameron Hymas"
    use module io.picolabs.pico alias wrangler
    logging on
    shares __testing
  }

  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "car", "type": "new_vehicle", "attrs": [ "name" ] },
                              { "domain": "collection", "type": "empty" } ] }

    nameFromName = function(name) {
      "Vehicle -  " + name + " Pico"
    }
  }


  rule create_vehicle {
  	select when car new_vehicle

  	pre{
      name = event:attr("name")
      exists = ent:vehicles >< name
      eci = meta:eci
  	}

    if exists then
      send_directive("vehicle_ready")
        with name = name

    fired { }
    else {
      raise pico event "new_child_request"
        attributes { "dname": nameFromName(name),
                     "color": "#FF69B4",
                     "name": name }
    }
  }



  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      the_vehicle = event:attr("new_child")
      name = event:attr("rs_attrs"){"name"}
    }
    if name.klog("found name: ")
    then
      send_directive("register child rulesets")
        with name = name 
        vehicle = the_vehicle

      event:send(
     { "eci": the_vehicle.eci, "eid": "install-ruleset",
       "domain": "pico", "type": "new_ruleset",
       "attrs": { "rid": "Subscriptions", "name": name } } )

      event:send(
      { "eci": the_vehicle.eci, "eid": "install-ruleset",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "base": meta:rulesetURI, "url": "trip_store.krl", "name": name } } )

      event:send(
      { "eci": the_vehicle.eci, "eid": "install-ruleset",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "base": meta:rulesetURI, "url": "track_trips2.krl", "name": name } } )

    fired {
      ent:vehicles := ent:vehicles.defaultsTo({});
      ent:vehicles{[name]} := the_vehicle
    }
  }


  rule collection_empty {
    select when collection empty
    always {
      ent:vehicles := {}
    }
  }


}








