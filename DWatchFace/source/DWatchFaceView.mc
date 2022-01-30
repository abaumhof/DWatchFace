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
	var nexttide1 = "";
	var nexttide2 = "";
	var nexttide = "";
	var tidemax=0.0;
	var tidemin=100.0;
	var smallNumFont=Graphics.FONT_XTINY;
	var WeatherIconFont;
	var DeaswatchFont;
	var sunrise_bitmap;
	var sunset_bitmap;
	var lastupdated = "N/A";
	var is_epix = true;
	var inLowPower=false;
    var canBurnIn=false;
    var upTop=true;
    var screenWidth = System.getDeviceSettings().screenWidth;
	var screenHeight = System.getDeviceSettings().screenHeight;
	const RAND_MAX = 0x7FFFFFF;
	
	// return a random value on the range [0, m]
	function random(m) {
		var r = Math.rand();
		return (r % m);
	}

    function initialize() {
        WatchFace.initialize();
        
        Math.srand(System.getTimer());
        var sSettings=System.getDeviceSettings();
        //first check if the setting is available on the current device
        if(sSettings has :requiresBurnInProtection) {
            //get the state of the setting      
            canBurnIn=sSettings.requiresBurnInProtection;
        }
        is_epix = canBurnIn;
        
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
        DeaswatchFont=WatchUi.loadResource(Rez.Fonts.deaswatch);
        
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
    
    function calculate_nexttides(tides as Dictionary)
    {
    	var t = "time";
    	var i=0;
    	var max=2;
    	
    	//var now = new Time.Moment(Time.now().value());
    	var nowG = Gregorian.info((new Time.Moment(Time.now().value())), Time.FORMAT_SHORT);
    	var optionsG = {
			    :year   => nowG.year,
			    :month  => nowG.month, // 3.x devices can also use :month => Gregorian.MONTH_MAY
			    :day    => nowG.day,
			    :hour   => nowG.hour,
			    :minute => nowG.min
			};
    	var now = Gregorian.moment(optionsG);
    	
    	for (var r = 0; r < tides["tides"].size(); r++) {
    		t = tides["tides"][r]["time"];
    		var y = t.substring(0,4).toNumber();
    		var m = t.substring(5,7).toNumber();
    		var d = t.substring(8,10).toNumber();
    		var h = t.substring(11,13).toNumber();
    		var mi = t.substring(14,16).toNumber();
    		
    		var options = {
			    :year   => y,
			    :month  => m, // 3.x devices can also use :month => Gregorian.MONTH_MAY
			    :day    => d,
			    :hour   => h,
			    :minute => mi
			};
    		var date = Gregorian.moment(options);
    		if (date.greaterThan(now)) {
    			var ishigh = tides["tides"][r]["isHigh"];
    			var height = tides["tides"][r]["height"];
    			// H 21:13 - 1.2m
    			if (i == 0) {
    				//nexttide1 = "" +  height.format("%.1f");
    				if (ishigh == true) { 
    					//nexttide1 = "H " + h + ":" + mi + " - " + height.format("%.1f") + "m";
    					nexttide1 = "" +  height.format("%.1f") + "m H";
    				} else { 
    					nexttide1 = "" +  height.format("%.1f") + "m L";
    				}
    				nexttide = "" + h + ":" + mi;
    				i++;
    			} else if (i == 1) {
    				nexttide2 = "" +  height.format("%.1f");
    				if (ishigh == true) { 
    					//nexttide1 = "H " + h + ":" + mi + " - " + height.format("%.1f") + "m";
    					nexttide2 = "" +  height.format("%.1f") + "m H";
    				} else { 
    					nexttide2 = "" +  height.format("%.1f") + "m L";
    				}
    				i++;
    			}
    		}
    		
    	}
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
    	var offsetY=0;
    	var multiplier=1.0;
    	var myTime = System.getClockTime(); // ClockTime object
    	
    	if (is_epix) {
    		dimheight=310;		// 416
    		width=416;
    		height=300;
    		w=12; 
    		offsetY = 90;
    	}
    	
    	//dc.fillRectangle(10,10,200,200);
    	// draw now 26 lines
    	if (initTides == true) {
    		multiplier = (dimheight - start) / tidemax;
    		
    		for( var i = 2; i < n; i += 1 ) {
    			if (i==2 || i==8 || i==14 || i==20 || i==26) {
    			//if (i % 2 == 0) {
    				// this is the text on top 
	    			dc.drawText(i*w + i + 4 + offsetX,offsetY + dimheight - (multiplier * tidebars[i-2]) - 10,smallNumFont,""+(i-2),Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	    		}
    			if ((i-2) == myTime.hour) {
    				//dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
    				dc.setColor(0xFF9933, Graphics.COLOR_BLACK);
    			}

	    		dc.fillRoundedRectangle(i*w + i + offsetX, offsetY + dimheight - (multiplier * tidebars[i-2]), w, height-(dimheight - (multiplier * tidebars[i-2])),5);
	    		//dc.drawRectangle(i*w + i + offsetX, offsetY + dimheight - (multiplier * tidebars[i-2]), w, height-(dimheight - (multiplier * tidebars[i-2])));

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
    	var BurnOffset = 0;
    	
	    if(dc has :setAntiAlias) {
	        dc.setAntiAlias(true);
	    }
	    

	    
	    if(inLowPower) {
			if(canBurnIn) {
				//move things on the epix
				BurnOffset=(upTop) ? 3 : -3;
				upTop=!upTop;
			}
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
       dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
       
        /*
        <shape type="rectangle" x="0" y="8%" width="100%" height="1" color="Graphics.COLOR_DK_GRAY" />
		<shape type="rectangle" x="0" y="19%" width="100%" height="1" color="Graphics.COLOR_DK_GRAY" />
		<shape type="rectangle" x="0" y="30%" width="100%" height="1" color="Graphics.COLOR_DK_GRAY" />
		
		<!-- 
		<shape type="rectangle" x="0" y="70%" width="100%" height="1" color="Graphics.COLOR_DK_GRAY" />
		 -->
		 
		<shape type="rectangle" x="center" y="8%" width="1" height="22%" color="Graphics.COLOR_DK_GRAY" />
		
		<shape type="rectangle" x="64%" y="49%" width="16%" height="1" color="Graphics.COLOR_DK_GRAY" />
		*/
		
        /*
        var o=24;
        dc.drawText(o,188,smallNumFont,"0",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(o+(5*11),188,smallNumFont,"6",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(o+(11*11) - 3,188,smallNumFont,"12",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(o+(17*11) - 3,188,smallNumFont,"18",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(o+(23*11) - 3,188,smallNumFont,"24",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	    */
        
        DeaswatchFont = Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
        var HYoffset = 0;
        var HXoffset = 0;
        
        if (DeaswatchFont != Graphics.FONT_SYSTEM_NUMBER_THAI_HOT) {
        	HYoffset = 25;
        	HXoffset = 10;
        }
        
        var rmulti1 = random(24);
        var rmulti2 = random(24);
        
        rmulti1 = 10;
        rmulti2 = 10;
        
        rmulti1 = 25;
        rmulti2 = 0;
        var dateoffsetx=0;
        
        if(inLowPower) {
			if(canBurnIn) {
				if (upTop) {  
					BurnOffset = 4;
				} else {
					BurnOffset = -4;
				}
				dateoffsetx = 20;
			}
		}
		
        // hours
        //var viewHour = View.findDrawableById("TimeLabelHour") as Text;
        ////viewHour.setColor(getApp().getProperty("ForegroundColor") as Number);
        //viewHour.setText("" + hours);        
        dc.drawText(HXoffset + rmulti1*BurnOffset + screenWidth*0.57, HYoffset + rmulti2*BurnOffset + screenHeight*0.32, DeaswatchFont, "" + hours, Graphics.TEXT_JUSTIFY_RIGHT);
        
        // minutes
        //var viewMinutes = View.findDrawableById("TimeLabelMinutes") as Text;
        ////viewMinutes.setColor(getApp().getProperty("ForegroundColor") as Number);
        //viewMinutes.setText(clockTime.min.format("%02d"));
        dc.drawText(rmulti1*BurnOffset + screenWidth*0.72 - dateoffsetx, rmulti2*BurnOffset + screenHeight*0.30, Graphics.FONT_SYSTEM_NUMBER_MILD, clockTime.min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
        
        // date
        //var viewDate = View.findDrawableById("DateLabel") as Text;
        ////viewDate.setColor(getApp().getProperty("ForegroundColor") as Number);
        ////viewDate.setText("TUE 06");
        //viewDate.setText(datestr);
        dc.setColor(0xFF9933, Graphics.COLOR_BLACK);
        dc.drawText(rmulti1*BurnOffset + screenWidth*0.72 - dateoffsetx, rmulti2*BurnOffset + screenHeight*0.48, Graphics.FONT_SYSTEM_XTINY, datestr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        
        if(inLowPower && canBurnIn) {
        } else {
        	// only draw in high power mode
        	
        	// scaffolding
	        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
	        dc.fillRectangle(screenWidth*0.00, screenHeight*0.08, screenWidth*1.00, 1);
	        dc.fillRectangle(screenWidth*0.00, screenHeight*0.19, screenWidth*1.00, 1);
	        dc.fillRectangle(screenWidth*0.00, screenHeight*0.30, screenWidth*1.00, 1);
	        dc.fillRectangle(screenWidth*0.50, screenHeight*0.08, 1, screenHeight*0.22);
	        dc.fillRectangle(screenWidth*0.64, screenHeight*0.48, screenWidth*0.16, 1);
	        
	        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
	        
	        // draw SUNTS (always 8% more)
	        dc.setColor(0xFF9933, Graphics.COLOR_BLACK);
	        dc.drawText(screenWidth*0.12, screenHeight*0.30, Graphics.FONT_SYSTEM_TINY, "S", Graphics.TEXT_JUSTIFY_LEFT);
	        dc.drawText(screenWidth*0.12, screenHeight*0.38, Graphics.FONT_SYSTEM_TINY, "U", Graphics.TEXT_JUSTIFY_LEFT);
	        dc.drawText(screenWidth*0.12, screenHeight*0.46, Graphics.FONT_SYSTEM_TINY, "N", Graphics.TEXT_JUSTIFY_LEFT);
	        dc.drawText(screenWidth*0.12, screenHeight*0.54, Graphics.FONT_SYSTEM_TINY, "T", Graphics.TEXT_JUSTIFY_LEFT);
	        dc.drawText(screenWidth*0.12, screenHeight*0.62, Graphics.FONT_SYSTEM_TINY, "S", Graphics.TEXT_JUSTIFY_LEFT);
			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
			
			// draw battery label
			//var viewBattery = View.findDrawableById("batteryLabel") as Text;
			//viewBattery.setText("" + System.getSystemStats().battery.toNumber() + "%");
	        dc.drawText(screenWidth*0.60, screenHeight*0.0, Graphics.FONT_SYSTEM_XTINY, "" + System.getSystemStats().battery.toNumber() + "%", Graphics.TEXT_JUSTIFY_CENTER);
			
			//var viewWindData= View.findDrawableById("windData") as Text;
			if ((initTides == true) && (bgdata != null) && (bgdata instanceof Dictionary)) {
				//viewWindData.setText(bgdata["wind"]["speed"] + " " + degToCompass(bgdata["wind"]["direction"]));
				dc.drawText(screenWidth*0.43, screenHeight*0.21, Graphics.FONT_SYSTEM_XTINY, bgdata["wind"]["speed"] + " " + degToCompass(bgdata["wind"]["direction"]), Graphics.TEXT_JUSTIFY_RIGHT);
			} else {
				//viewWindData.setText("N/A");
				dc.drawText(screenWidth*0.43, screenHeight*0.21, Graphics.FONT_SYSTEM_XTINY, "N/A", Graphics.TEXT_JUSTIFY_RIGHT);
			}
			
			dc.setColor(0xFF9933, Graphics.COLOR_BLACK);
			//var viewSurfData= View.findDrawableById("surfData") as Text;
			if ((initTides == true) && (bgdata != null) && (bgdata instanceof Dictionary)) {
				dc.drawText(screenWidth*0.57, screenHeight*0.11, Graphics.FONT_SYSTEM_XTINY, bgdata["waveswell"]["waveheight"], Graphics.TEXT_JUSTIFY_LEFT);
				//viewSurfData.setText(bgdata["waveswell"]["waveheight"]);
			} else {
				//viewSurfData.setText("N/A");
				dc.drawText(screenWidth*0.57, screenHeight*0.11, Graphics.FONT_SYSTEM_XTINY, "N/A", Graphics.TEXT_JUSTIFY_LEFT);
			}
			//var viewSunData= View.findDrawableById("sunData") as Text;
			
			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
			
			//var viewSwellData= View.findDrawableById("swellData") as Text;
			if ((initTides == true) && (bgdata != null) && (bgdata instanceof Dictionary)) {
				//viewSwellData.setText(bgdata["waveswell"]["swellheight"] + " " + bgdata["waveswell"]["swellperiod"] + " " + degToCompass(bgdata["waveswell"]["swelldirection"]));
				dc.drawText(screenWidth*0.57, screenHeight*0.21, Graphics.FONT_SYSTEM_XTINY, bgdata["waveswell"]["swellheight"] + " " + bgdata["waveswell"]["swellperiod"] + " " + degToCompass(bgdata["waveswell"]["swelldirection"]), Graphics.TEXT_JUSTIFY_LEFT);
			} else {
				//viewSwellData.setText("N/A");
				dc.drawText(screenWidth*0.57, screenHeight*0.21, Graphics.FONT_SYSTEM_XTINY, "N/A", Graphics.TEXT_JUSTIFY_LEFT);
			}
			
			// the next two tide heights
			dc.drawText(screenWidth*0.96, screenHeight*0.58, Graphics.FONT_SYSTEM_XTINY, nexttide1, Graphics.TEXT_JUSTIFY_RIGHT);
			dc.drawText(screenWidth*0.96, screenHeight*0.64, Graphics.FONT_SYSTEM_XTINY, nexttide2, Graphics.TEXT_JUSTIFY_RIGHT);
			
			
			if (lastupdated == null) {
				lastupdated = "N/A";
			}
			//var viewStatusData= View.findDrawableById("statusLabel") as Text;
			//viewStatusData.setText(lastupdated);
						
			dc.drawText(screenWidth*0.50, screenHeight*0.94, Graphics.FONT_SYSTEM_XTINY, lastupdated, Graphics.TEXT_JUSTIFY_CENTER); 
			
			var dx=54;
			var dy=30;
			if (is_epix) {
				dx=84;
				dy=50;
			}
			dx += BurnOffset;
			if ((initTides == true) && (bgdata != null) && (bgdata instanceof Dictionary)) {
				//viewSunData.setText(bgdata["nextsun"]);
				dc.drawText(screenWidth*0.43, screenHeight*0.11, Graphics.FONT_SYSTEM_XTINY, bgdata["nextsun"], Graphics.TEXT_JUSTIFY_RIGHT);
				
				if (bgdata["nextsuntype"].find("sunrise") != null) {
					dc.drawBitmap(dx, dy, sunrise_bitmap);
				} else {
					dc.drawBitmap(dx, dy, sunset_bitmap);
				}
			} else {
				dc.drawBitmap(dx, dy, sunrise_bitmap);
				//viewSunData.setText("N/A");
				dc.drawText(screenWidth*0.43, screenHeight*0.11, Graphics.FONT_SYSTEM_XTINY, "N/A", Graphics.TEXT_JUSTIFY_RIGHT);
			}		
		}
		
		// update the weather on the right
		/* don't do that... I somehow got an exception for this today... And it's not really that useful
		var wi = WI(Weather.getCurrentConditions().condition);
		dc.drawText(275, 130, WeatherIconFont, wi, Graphics.TEXT_JUSTIFY_RIGHT);
		
		var cast=Weather.getDailyForecast();
		if(cast!=null) {
			dc.drawText(275, 156, WeatherIconFont, WI(cast[0].condition), Graphics.TEXT_JUSTIFY_RIGHT);
		}
		*/
		
		if(inLowPower && canBurnIn) {
		} else {
			// only draw Tides if not in low power mode
			if (initTides == true) {
				drawTides(dc);
			}
			calculate_nexttides(bgdata);
		}	
        
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // This method is called when the device re-enters sleep mode.
    function onEnterSleep() {
        inLowPower=true;
        WatchUi.requestUpdate(); 
		var drawable = findDrawableById("BatteryHelper");
		drawable.onEnterSleep();
    }
    
    // This method is called when the device exits sleep mode.
    function onExitSleep() {
        inLowPower=false;
        WatchUi.requestUpdate(); 
        var drawable = findDrawableById("BatteryHelper");
		drawable.onExitSleep();
    }

}
