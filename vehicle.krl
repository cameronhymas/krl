ruleset vehicle {
  meta {
    name "vehicle"
    author "Cameron Hymas"
    shares __testing
  }

  global {
    __testing = { "queries": [ { "name": "__testing" } ] }
  }

  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      attributes = event:attrs().klog("subcription: ")
    }
    always {
      raise wrangler event "pending_subscription_approval"
        attributes attributes
    }
  }
}