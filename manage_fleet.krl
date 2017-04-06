ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    author "Cameron Hymas"
    use module io.picolabs.pico alias wrangler
    logging on
    shares __testing, getVehicles
    provides getVehicles
    use module Subscriptions
  }

  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "car", "type": "new_vehicle", "attrs": [ "name" ] },
                              { "domain": "car", "type": "unneeded_vehicle", "attrs": [ "name" ] },
                              { "domain": "collection", "type": "empty" },
                              { "domain": "car", "type": "clear_report" },
                              { "domain": "car", "type": "get_vehicles" },
                              { "domain": "car", "type": "get_report" },

                              { "domain": "car", "type": "scatter_report" },

                              { "domain": "car", "type": "get_vehicle", "attrs": ["name"] } ] }

    nameFromName = function(name) {
      "Vehicle -  " + name + " Pico"
    }

    getVehicles = function() {
      // return vehicle subscriptions
      Subscriptions:getSubscriptions()
    }

    getVehicleFromName = function(name){
      ent:vehicles{[name]}
    }
  }

  rule get_vehicle {
    select when car get_vehicle

    pre {
      name = event:attr("name").klog("name")
      exists = ent:vehicles >< name.klog("exists")
    }

    if exists.klog("does it?") then
      getVehicleFromName(name)
  }


  rule get_vehicles {
    select when car get_vehicles

    //getVehicles()
    Subscriptions:getSubscriptions()
  }


  rule create_vehicle {
    select when car new_vehicle

    pre{
      name = event:attr("name")
      exists = ent:vehicles >< name
      eci = meta:eci
    }

    if exists.klog("maybe ") then
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
      event:send(
      { "eci": the_vehicle.eci, "eid": "install-ruleset",
       "domain": "pico", "type": "new_ruleset",
       "attrs": { "rid": "Subscriptions", "name": name } } )

      event:send(
      { "eci": the_vehicle.eci, "eid": "install-ruleset",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "base": meta:rulesetURI, "url": "vehicle.krl", "name": name } } )

      event:send(
      { "eci": the_vehicle.eci, "eid": "install-ruleset",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "base": meta:rulesetURI, "url": "trip_store.krl", "name": name } } )

      event:send(
      { "eci": the_vehicle.eci, "eid": "install-ruleset",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "base": meta:rulesetURI, "url": "track_trips2.krl", "name": name } } )

      send_directive("maybe this worked")
        with vehicle = the_vehicle.klog("vehicular stuff")


    fired {
      raise car event "subscribe_vehicle"
        with vehicle = the_vehicle
        name = name;

      ent:vehicles := ent:vehicles.defaultsTo({});
      ent:vehicles{[name]} := the_vehicle
    }
  }


  rule subscribe_vehicle {
    select when car subscribe_vehicle
    pre {
      vehicle = event:attr("vehicle").klog("Vehicle: ")
      name = event:attr("name").klog("Vehcile Name: ")
    }

    send_directive("subscribe time")
        with vehicle = vehicle

    event:send(
    { "eci": meta:eci, "eid": "subscription",
      "domain": "wrangler", "type": "subscription",
      "attrs": { "name": name,
                 "name_space": "car",
                 "my_role": "fleet",
                 "subscriber_role": "vehicle",
                 "channel_type": "subscription",
                 "subscriber_eci": vehicle.eci } } )
  }

  rule delete_vehicle {
    select when car unneeded_vehicle

    pre {
      name = event:attr("name")
      exists = ent:vehicles >< name
      vehicle = getVehicleFromName(name).klog("the vehicle is found?: ")
      eci = meta:eci
      child_to_delete = getVehicleFromName(name).klog("the vehicle to delete: ")
    }

    if exists.klog("existsings") then
      send_directive("vehicle_deleted")
        with name = name
        vehicle = vehicle

      // delete subscription
      event:send(
      { "eci": vehicle.eci, "eid": "del",
        "domain": "wrangler", "type": "subscription_cancellation",
        "attrs": { "subscription_name": "car:" + name } } )

    fired {
      // remove pico
      raise pico event "delete_child_request"
        attributes child_to_delete;

      ent:vehicles{[name]} := null
    }
  }



  rule generate_report {
    select when car get_report
    foreach Subscriptions:getSubscriptions() setting (subscription)
    pre {
      sub_attrs = subscription{"attributes"}
      data = http:get("http://localhost:8080/sky/cloud/" + sub_attrs{"outbound_eci"} + "/trip_store/trips"){["content"]}.decode()
      length = Subscriptions:getSubscriptions().length().klog("length")
    }

    if data
    then 
      noop()

    fired {
      ent:count := ent:count.defaultsTo(0).klog("default");
      ent:count := ent:count + 1;

      ent:report := ent:report.defaultsTo({});
      ent:report{[sub_attrs{"subscription_name"}]} := { "vehicles": length, "responding": ent:count.klog("count"), "trips": data}
    }
  }


  rule clear_report{
    select when car clear_report

    always {
      ent:report := {};
      ent:trips := {};
      ent:sg_trips := {};
      ent:count := null
    }
  }



  rule collection_empty {
    select when collection empty
    always {
      ent:vehicles := {}
    }
  }



  rule scatter_report {
    select when car scatter_report

    foreach Subscriptions:getSubscriptions() setting (subscription)
    pre {
      sub_attrs = subscription{"attributes"}.klog("attrs")
      sub_eci = sub_attrs{"subscriber_eci"}.klog("eci")
      rcn = "rcn 0"
      role = sub_attrs{"subscriber_role"}.klog("subscriber_role")
    }

    //if (role neq "fleet").klog("equals?") then 
    event:send(
      { "eci": sub_eci, "eid": "gather_trip_data",
        "domain": "car", "type": "gather_trip_data",
        "attrs": { "name": sub_attrs{"subscription_name"},
                   "rcn": rcn.klog("rcn"),
                   "eci": meta:eci } } )

     fired {
      ent:sg_trips := ent:sg_trips.defaultsTo({});
      ent:sg_trips{[rcn]} = {};

      ent:id := ent:id.defaultsTo(0)
      //ent:id := ent:id + 1;
    }
  }

  rule gather_report {
    select when car gather_report 
    pre {
      attr = event:attr().klog("AATTTRRR")
      name = event:attr("name").klog("gathering now - name: ")
      //rcn = event:attr("rcn").klog("gathering now - rcn: ")
      //trips = event:attr("trips").klog("gathering now - trips: ")
      //vehicleCount = Subscriptions:getSubscriptions().length().klog("vehicleCount: ")
      //currentCount = ent:sg_trips{[rcn]}.length().klog("currentCount: ")
    }

    always {
      //ent:sg_trips{[rcn][name]} := {"vehicles": vehicleCount, "responding": currentCount, "trips": trips};

      //ent:id := ent:id + 1
    }
  }
}








