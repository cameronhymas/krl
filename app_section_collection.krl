ruleset app_section_collection {
  meta {
    name "App Section Collection"
    author "Cameron Hymas"
    use module io.picolabs.pico alias wrangler
    logging on
    shares __testing, showChildren
    provides showChildren
  }

  global {
    __testing = { "events": [ { "domain": "section", "type": "needed", "attrs": [ "section_id" ] },
                              { "domain": "collection", "type": "empty" },
                              { "domain": "section", "type": "get_section", "attrs": [ "section_id" ] } ],
                 "queries": [ { "name": "showChildren" } ] }

    nameFromID = function(section_id) {
      "Section " + section_id + " Pico"
    }

    showChildren = function() {
      wrangler:children()
    }

    getSectionFromId = function(id){
      ent:sections{[id]}
    }
  }

  rule get_vehicle {
    select when section get_section

    pre {
      section_id = event:attr("section_id").klog("id")
      exists = ent:sections >< section_id.klog("exists")
    }
    if exists.klog("does it?") then
      getSectionFromId(section_id)
  }



  rule section_already_exists {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
    }
    if exists.klog("exists maybe") then
      send_directive("section_ready")
          with section_id = section_id
  }

  rule section_needed {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
    }
    if not exists
    then
      noop()
    fired {
      raise pico event "new_child_request"
        attributes { "dname": nameFromID(section_id),
                     "color": "#FF69B4",
                     "section_id": section_id }
    }
  }

  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      the_section = event:attr("new_child").klog("child")
      section_id = event:attr("rs_attrs"){"section_id"}
    }
    if section_id.klog("found section_id")
    then
      event:send(
      { "eci": the_section.eci, "eid": "install-ruleset",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "base": meta:rulesetURI, "url": "app_section.krl", "section_id": section_id } } )
    fired {
      ent:sections := ent:sections.defaultsTo({});
      ent:sections{[section_id]} := the_section
    }
  }

  rule collection_empty {
    select when collection empty
    always {
      ent:sections := {}
    }
  }
}





