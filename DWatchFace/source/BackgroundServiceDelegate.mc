using Toybox.Background;
using Toybox.System as System;
using Toybox.Communications;

// The Service Delegate is the main entry point for background processes
// our onTemporalEvent() method will get run each time our periodic event
// is triggered by the system.

(:background)
class BgbgServiceDelegate extends Toybox.System.ServiceDelegate {
	var ts;
	
	function initialize() {
		System.ServiceDelegate.initialize();
		inBackground=true;				//trick for onExit()
	}
	
    function onTemporalEvent() {
    	var my_url = "https://baumhof.net/coastalwatch/report.json";                         // set the url
    	var url = $.globalServerUrl;
    	
    	System.println("bg start1: " + $.globalServerUrl);
    	if (($.globalServerUrl == null) || ($.globalServerUrl.length() < 3)) {
    		/* this doesn't work in a Background Service
    		url = getProperty("DWatchfaceServer");
	        if ((url) && (url.length() > 3)) {
	        	// take the default one for now
	        	$.globalServerUrl = url;
	        	System.println("bg start:");
	    		makeRequest(url);
	        }
	        */
	        Background.exit("ERROR: server not configured");
    	} else {
    	
	    	System.println("bg start:");
	    	makeRequest(url);
	    	//var now=System.getClockTime();
	    	//ts=now.hour+":"+now.min.format("%02d");
	
	        //just return the timestamp
	        //Background.exit(ts);
	    }
    }
    
    //function onReceive(responseCode as Number, data as Dictionary?) as Void {
    function responseCallback(responseCode, data) {
    	//System.println("Request done: " + responseCode);
    	var res;
    	
        if (responseCode == 200) {
            //System.println("Request Successful");                   // print success
            System.println(data);
            //System.println("bg sunrise = " + data["sunrise"]);
            res = data;
        } else {
            System.println("Response: " + responseCode);            // print response code
            res = "ERROR: " + responseCode;
        }
        //System.println("bg exits now: "+ts);
        Background.exit(res);
    }
    
	function makeRequest(url as String) {
		var params = null;
        //var params = {                                              // set the parameters
        //    "definedParams" => "123456789abcdefg"
        //};

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
            :headers => {                                           // set headers
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
            // set response type
            //:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_URL_ENCODED
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        //var responseCallback = method(:onReceive);                  // set responseCallback to
        // onReceive() method
        // Make the Communications.makeWebRequest() call
        System.println("Sending Request to " + url);   
        Communications.makeWebRequest(url, params, options, method(:responseCallback));
    }
}
