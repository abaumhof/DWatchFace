import Toybox.Application;
using Toybox.Background;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Time as Time;

// variables for the background process
var bgdata="N/I";
var canDoBG=false;
var inBackground=false;			//new 8-27
var initialBackgroundTask=true;
// keys to the object store data
var OSDATA="osdata";

(:background)
var globalServerUrl;

class DWatchFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        
        var my_url = "https://baumhof.net/coastalwatch/report.json"; 
        
        //var url = getApp().getProperty("DWatchfaceServer") as Url;
        var url = getProperty("DWatchfaceServer");
        if ((url == null) || (url.length() < 3)) {
        	// take the default one for now
        	//url = my_url;
        	$.globalServerUrl = "";
        } else {
        	$.globalServerUrl = url;
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
    	if(Toybox.System has :ServiceDelegate) {
     		canDoBG=true;
 			
 			/* this doesn't work as I'll get an exception: Background time cannot be set less than 5 minutes since the last run
 			if (initialBackgroundTask == true) {
 				Background.registerForTemporalEvent(new Time.Moment(Time.today().value()));
 			} 
 			*/  		
    		//Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    		
    		if (initialBackgroundTask == true) {
	    		var lastTime = Background.getLastTemporalEventTime();
				if (lastTime != null) {
	    			// Events scheduled for a time in the past trigger immediately
				    var nextTime = lastTime.add(new Time.Duration(5 * 60));
				    Background.registerForTemporalEvent(nextTime);
				} else {
					Background.registerForTemporalEvent(Time.now());
				} 
			}
				
    		//Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    	} else {
    		System.println("****background not available on this device****");
    	}
        return [ new DWatchFaceView() ] as Array<Views or InputDelegates>;
    }
    
    function onBackgroundData(data) {
    	var now=System.getClockTime();
    	var ts=""+now.hour+":"+now.min.format("%02d");
    	
        System.println("onBackgroundData="+data);
        bgdata=data;
        if (bgdata instanceof Dictionary) { 
        	bgdata.put("lastupdated", ts);
        	Storage.setValue("serverdata", bgdata);
        	
        	// now that we have done it once, only do it every 60 minutes
	        if (initialBackgroundTask == true) {
	        	Background.registerForTemporalEvent(new Time.Duration(60 * 60));
	        	initialBackgroundTask = false;
	        }
        } else {
        
        	// if it isn't a Dictionary, keep doing it every 5 minutes
        	System.println("doing it again in 5");
        	initialBackgroundTask = true;
        	Background.registerForTemporalEvent(new Time.Duration(5 * 60));
        }  
        
       
        if (bgdata instanceof Dictionary) { 
        	Application.getApp().setProperty(OSDATA,bgdata);
        	WatchUi.requestUpdate();
        }
    } 
    
    function getServiceDelegate(){
        return [new BgbgServiceDelegate()];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

}

function getApp() as DWatchFaceApp {
    return Application.getApp() as DWatchFaceApp;
}