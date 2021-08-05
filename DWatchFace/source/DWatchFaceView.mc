import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Math;
using Toybox.ActivityMonitor;
using Toybox.Time.Gregorian;
using Toybox.Time;
using Toybox.Attention;
using Toybox.Weather;

// custom fonts here: https://forums.garmin.com/developer/connect-iq/f/discussion/2193/using-custom-fonts

class DWatchFaceView extends WatchUi.WatchFace {
	var initTides=false;
	var tidebars = [];
	var tidemax=0.0;
	var tidemin=100.0;
	var smallNumFont=Graphics.FONT_XTINY;
	var WeatherIconFont;
	var sunrise_bitmap;
	var sunset_bitmap;
	var lastupdated = "N/A";
	
    function initialize() {
        WatchFace.initialize();
        
        //read last values from the Object Store
        //counter now read in app initialize
        //var temp=App.getApp().getProperty(OSCOUNTER);
        //if(temp!=null && temp instanceof Number) {counter=temp;}
 
        //var temp=App.getApp().getProperty(OSDATA);
        var temp=null;
        //if(temp!=null && temp instanceof String) {bgdata=temp;}
        if(temp!=null && temp instanceof Dictionary) {bgdata=temp;}
        
        smallNumFont=WatchUi.loadResource(Rez.Fonts.roboto1);
        WeatherIconFont=WatchUi.loadResource(Rez.Fonts.shnweather);
        
        sunset_bitmap = WatchUi.loadResource(Rez.Drawables.SunsetIcon);
        sunrise_bitmap = WatchUi.loadResource(Rez.Drawables.SunriseIcon);
        
        var myServerdata = Application.Storage.getValue("serverdata");
        if (myServerdata != null) {
        	bgdata = myServerdata;
        }
    }
	
    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }
    
    function th(a, e, w, t)
    {
    	var tt = e + a*Math.cos(w * t);
    	return tt;
    }
    
    // from here: https://socratic.org/questions/use-a-sine-function-to-describe-the-height-of-the-tides-of-the-ocean-if-high-tid
    function initTidesHeight(tides as Dictionary)
    {
    	var a = 0.0, min = 0.0, max = 0.0, e = 0.0, w = 0.0;
    	var offset=0;
    	var offsetmin=0;
    	var t="time";
    	var tt = 0.0;
    	var nextoffsetmin = 0;
    	var nextoffsetindex = 0;
    	
    	tidebars = [];
    	for (var r = 0 ; r <= 2; r = r + 2) {
	    	if (tides["tides"][r]["isHigh"] == true) {
	    		max = tides["tides"][r]["height"];
	    		t = tides["tides"][r]["time"];
	    		offset = t.substring(11,13).toNumber();
	    		System.println("round " + r + ", time = " + tides["tides"][r]["time"] + " offset = " + offset);
	    	} else {
	    		min = tides["tides"][r]["height"];
	    		
	    		t = tides["tides"][r]["time"];
	    		offsetmin = t.substring(11,13).toNumber();
	    	}
	    	if (tides["tides"][r+1]["isHigh"] == true) {
	    		max = tides["tides"][r+1]["height"];
	    		t = tides["tides"][r+1]["time"];
	    		offset = t.substring(11,13).toNumber();
	    		System.println("round " + r + ", time = " + tides["tides"][r+1]["time"] + " offset = " + offset);
	    	} else {
	    		min = tides["tides"][r+1]["height"];
	    		
	    		t = tides["tides"][r+1]["time"];
	    		offsetmin = t.substring(11,13).toNumber();
	    	}
	    	if (max > tidemax) {
	    		tidemax=max;
	    	}
	    	if (min < tidemin) {
	    		tidemin=min;
	    	}
	    	
	    	// only in the first round
	    	// check whether the min is to the right of max and if not take the next min
	    	if (r == 0) {
		    	if (offsetmin < offset) {
		    		var no = 2;
		    		if (tides["tides"][no]["isHigh"] == true) {
		    			no = 3;
		    		}
		    		t = tides["tides"][no]["time"];
	    			nextoffsetmin = t.substring(11,13).toNumber();
	    			nextoffsetindex = nextoffsetmin-12;
		    	} else {
		    		nextoffsetmin = offsetmin;
		    		nextoffsetindex = offsetmin;
		    	}
		    } else {
		    	nextoffsetmin = 28;
		    	/*
		    	if (nextoffsetmin < 12) {
		    		nextoffsetmin = 24 - nextoffsetmin + 1;
		    	}
		    	*/
		    }
	    	
	    	e = 0.5*(max + min);
	    	a = max - e;
	    	w = 2 * Math.PI / 12; 				// this is assuming an exact 12h high-tide to high-tide
	    	
	    	// make sure we don't "glue" the two sin curves together at 12h, but at the next low tide after the first high tide
	    	var start = 0;
	    	if (r != 0) {
	    		start = nextoffsetindex;
	    	}
	    	//tide = E + A*cos(w*t)
	    	//for (var i=0; i<12; i = i+1) {
	    	for (var i=start; i<nextoffsetmin-1; i = i+1) {
	    		tt = th(a, e, w, i-offset);
	    		tidebars.add(tt);
	    		//System.println("tide: h=" + i + ", height=" + tt);
	    	}
	    }  	
    	initTides = true;
    }
    
    
    function drawTides(dc as Dc) as Void {
    	var dimheight=280;
    	var width=280;
    	var n=26;
    	var height=264;
    	//var w=9;
    	var w=7;
    	var start=196;
    	var offsetX=24;
    	var multiplier=1.0;
    	var myTime = System.getClockTime(); // ClockTime object
    	
    	
    	//dc.fillRectangle(10,10,200,200);
    	// draw now 26 lines
    	if (initTides == true) {
    		multiplier = (dimheight - start) / tidemax;
    		
    		for( var i = 2; i < n; i += 1 ) {
    			if (i==2 || i==8 || i==14 || i==20 || i==26) {
    			//if (i % 2 == 0) {
    				// this is the text on top 
	    			dc.drawText(i*w + i + 4 + offsetX,dimheight - (multiplier * tidebars[i-2]) - 10,smallNumFont,""+(i-2),Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	    		}
    			if ((i-2) == myTime.hour) {
    				dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
    			}

	    		dc.fillRectangle(i*w + i + offsetX, dimheight - (multiplier * tidebars[i-2]), w, height-(dimheight - (multiplier * tidebars[i-2])));

	    		if ((i-2) == myTime.hour) {
    				dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    			}
	    	}
    	} else {
    		/* don't draw anything if we don't have any data
	    	for( var i = 2; i < n; i += 1 ) {
	    		dc.drawRectangle(i*w + i, start, w, height-start);
	    	}
	    	*/
	    }
    }

	function degToCompass(deg) {
		var arr=["N","NNE","NE","ENE","E","ESE", "SE", "SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"];
		
		var val = ((deg / 22.5)+0.5).toNumber();
		var valX = val % 16;
		
		return arr[valX];
	}
	
	// this function gives me the right icon for the weather from the shnfont
	// from https://forums.garmin.com/developer/connect-iq/f/discussion/242116/weather-icons#pifragment-702=1
	function WI(v){
		var T="";
		if (v==0||v==40){T= "A";}
		else if(v==53){T="";}
		else if(v==1||v==22||v==23||v==52){T= "B";}
		else if(v==2||v==5){T= "C";}
		else if(v==20){T= "D";}
		else if(v==3||v==10||v==15||v==25||v==26){T= "E";}
		else if(v==11||v==13||v==14||v==24||v==27||v==31||v==45){T= "F";}
		else if(v==6||v==12||v==28){T= "G";}
		else if (v==8||v==9||(v>28&&v<43&&v!=31&&v!=34&&v!=40)){T= "I";}
		else {T= "H";}
	
		return T;
	}
	
    // Update the view
    function onUpdate(dc as Dc) as Void {
    	var datestr = "";
    	
	    if(dc has :setAntiAlias) {
	        dc.setAntiAlias(true);
	    }
	    
		if (($.globalServerUrl == null) || ($.globalServerUrl.length() < 3)) {
			var url = getApp().getProperty("DWatchfaceServer");
	        if ((url == null) || (url.length() < 3)) {
	        	// take the default one for now
	        	//url = my_url;
	        	$.globalServerUrl = "";
	        } else {
	        	$.globalServerUrl = url;
	        }
	    }
        
	    // check whether I need to update
	    if ((bgdata != null) && (bgdata instanceof Dictionary)) {
	    	var blu = bgdata["lastupdated"];
	    	if (lastupdated.find(blu) == null) {
	    		initTides = false;
	    	}
	    } else {
	    	// something went wrong here... bgdata is not a Dictionary
	    	var myServerdata = Application.Storage.getValue("serverdata");
	        if ((myServerdata != null) && (myServerdata instanceof Dictionary)) {
	        	bgdata = myServerdata;
	        }
	    }
	    
	    if (!initTides && (bgdata !=null)  && bgdata instanceof Dictionary) {
	    	initTidesHeight(bgdata);
	    	lastupdated = bgdata["lastupdated"];
	    	
	    	//var h = [];
	    	//h = ActivityMonitor.getHistory();
	    } else {
	    	if ((bgdata != null) && (bgdata instanceof String)) {
	    		lastupdated = bgdata;
	    	}
	    }
	    if ((globalServerUrl == null) || (globalServerUrl.length() < 3)) {
    		lastupdated = "Configure URL";
    	}
	    
	    //System.println("in onUpdate: data=" + bgdata);
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
        /*
            if (getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
            */
        }
        
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        
        datestr = today.day_of_week.toUpper() + " " + today.day.format("%02d");
        /*
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        // Update the view
        var view = View.findDrawableById("TimeLabel") as Text;
        view.setColor(getApp().getProperty("ForegroundColor") as Number);
        view.setText(timeString);
        */
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        // add stuff from here onwareds.
        
        /*
        var o=24;
        dc.drawText(o,188,smallNumFont,"0",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(o+(5*11),188,smallNumFont,"6",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(o+(11*11) - 3,188,smallNumFont,"12",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(o+(17*11) - 3,188,smallNumFont,"18",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(o+(23*11) - 3,188,smallNumFont,"24",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	    */
        
        var viewHour = View.findDrawableById("TimeLabelHour") as Text;
        //viewHour.setColor(getApp().getProperty("ForegroundColor") as Number);
        viewHour.setText("" + hours);
        
        var viewMinutes = View.findDrawableById("TimeLabelMinutes") as Text;
        //viewMinutes.setColor(getApp().getProperty("ForegroundColor") as Number);
        viewMinutes.setText(clockTime.min.format("%02d"));
        
        var viewDate = View.findDrawableById("DateLabel") as Text;
        //viewDate.setColor(getApp().getProperty("ForegroundColor") as Number);
        //viewDate.setText("TUE 06");
        viewDate.setText(datestr);

		var viewBattery = View.findDrawableById("batteryLabel") as Text;
		viewBattery.setText("" + System.getSystemStats().battery.toNumber() + "%");
		
		var viewSurfData= View.findDrawableById("surfData") as Text;
		if ((initTides == true) && (bgdata != null) && (bgdata instanceof Dictionary)) {
			viewSurfData.setText(bgdata["waveswell"]["waveheight"]);
		} else {
			viewSurfData.setText("N/A");
		}
		var viewSunData= View.findDrawableById("sunData") as Text;
		if ((initTides == true) && (bgdata != null) && (bgdata instanceof Dictionary)) {
			viewSunData.setText(bgdata["nextsun"]);
			if (bgdata["nextsuntype"].find("sunrise") != null) {
				dc.drawBitmap(54, 30, sunrise_bitmap);
			} else {
				dc.drawBitmap(54, 30, sunset_bitmap);
			}
		} else {
			dc.drawBitmap(54, 30, sunrise_bitmap);
			viewSunData.setText("N/A");
		}
		
		
		var viewSwellData= View.findDrawableById("swellData") as Text;
		if ((initTides == true) && (bgdata != null) && (bgdata instanceof Dictionary)) {
			viewSwellData.setText(bgdata["waveswell"]["swellheight"] + " " + bgdata["waveswell"]["swellperiod"] + " " + degToCompass(bgdata["waveswell"]["swelldirection"]));
		} else {
			viewSwellData.setText("N/A");
		}
		
		var viewWindData= View.findDrawableById("windData") as Text;
		if ((initTides == true) && (bgdata != null) && (bgdata instanceof Dictionary)) {
			viewWindData.setText(bgdata["wind"]["speed"] + " " + degToCompass(bgdata["wind"]["direction"]));
		} else {
			viewWindData.setText("N/A");
		}
		
		var viewStatusData= View.findDrawableById("statusLabel") as Text;
		if (lastupdated == null) {
			lastupdated = "N/A";
		}
		viewStatusData.setText(lastupdated);

		// update the weather on the right
		var wi = WI(Weather.getCurrentConditions().condition);
		dc.drawText(275, 130, WeatherIconFont, wi, Graphics.TEXT_JUSTIFY_RIGHT);
		
		var cast=Weather.getDailyForecast();
		if(cast!=null) {
			dc.drawText(275, 156, WeatherIconFont, WI(cast[0].condition), Graphics.TEXT_JUSTIFY_RIGHT);
		}
		
		if (initTides == true) {
			drawTides(dc);
		}	
        
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    	
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    	
    }

}
