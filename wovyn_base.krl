ruleset wovyn_base {
  meta {
        use module lesson_keys
        use module twilio alias twilio
        with account_sid = keys:twilio{"account_sid"}
        auth_token =  keys:twilio{"auth_token"}
  }
  global {
    temperature_threshold = 75;
  }

 rule process_heartbeat {
    select when wovyn heartbeat where event:attr("genericThing") 
    send_directive("wovyn", {"body" : "Heartbeat Received"});
    fired {
        raise wovyn event "new_temperature_reading" attributes { "temperature": event:attr("genericThing").get(["data", "temperature", 0, "temperatureF"]), "timestamp": time:now()};
    }
  }
 rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
    temp = event:attr("temperature");
    violation = event:attr("temperature") > temperature_threshold;
    
    }
    send_directive("violation", {"vio": violation, "temp" : temp});
    fired {
        raise wovyn event "threshold_violation" attributes {"temperature" : event:attr("temperature"), "timestamp" : event:attr("timestamp")} if violation;
    }
  }
 rule threshold_notification {
    select when wovyn threshold_violation
    twilio:send_sms("14433709548", "16677712304", "There was a violation");
 } 
}
