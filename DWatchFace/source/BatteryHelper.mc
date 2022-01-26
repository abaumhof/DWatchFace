import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Math;

/* This class calculates DIP - density-independent pixels to draw proportional battery on any  screen resolution.
 * from https://chariotsolutions.com/blog/post/how-to-make-a-watch-face-for-garmin-watches/
 */
 
class BatteryHelper extends WatchUi.Drawable {
	//hidden var dipX = 46.00; 		// 260 base
	//hidden var dipY = 214.00;		// 260 base
	hidden var dipX = 115.00; 		// 260 base
	hidden var dipY = 2.00;		// 260 base
	hidden var dipLength = 30.00;
	hidden var dipHeight = 15.00;
	hidden var noseCapHeight = 7;
	hidden var noseCapX = 76;
	hidden var noseCapY = 218;
	hidden var is_epix=true;
	var inLowPower=false;
    var canBurnIn=false;
	
	function initialize() {
		var dictionary = {
			:identifier => "BatteryHelper"
		};
		
		var sSettings=System.getDeviceSettings();
        //first check if the setting is available on the current device
        if(sSettings has :requiresBurnInProtection) {
            //get the state of the setting      
            canBurnIn=sSettings.requiresBurnInProtection;
        }
        is_epix = canBurnIn;
		if (is_epix) {
			self.dipX = 150.00;
			self.dipY = -106.00;
		}
		
		Drawable.initialize(dictionary);
		
		var screenWidth = System.getDeviceSettings().screenWidth;
		var screenHeight = System.getDeviceSettings().screenHeight;
		
		var xScale = 280.00 - screenWidth;
		var yScale = 280.00 - screenHeight;
		var xAspect = 280.00 / screenWidth;
		var yAspect = 280.00 / screenHeight;
		
		self.dipX = (self.dipX - xScale/6).toNumber();
		self.dipY = (self.dipY - yScale/1.2).toNumber();
		self.dipLength = (self.dipLength / xAspect).toNumber();
		self.dipHeight = (self.dipHeight / yAspect).toNumber();
		
		if (self.dipHeight % 2 != 0) {
			self.dipHeight = self.dipHeight -1;
		}
		if (self.dipHeight > 20) {
			self.dipHeight = 20;
		}
		
		self.noseCapHeight = self.dipHeight/2 + 1;
		self.noseCapX = self.dipX + self.dipLength -2;
		self.noseCapY = self.dipY + self.dipHeight/4;
		
		if (self.noseCapHeight % 2 != 0) {
			self.noseCapHeight = self.noseCapHeight -1;
		}
	}
	
	function draw(dc) {
		var batteryChargeLevel = System.getSystemStats().battery.toNumber();
		var isCharging = System.getSystemStats().charging;
		var chargeLevelFill = (batteryChargeLevel * (self.dipLength-4) / 100).toNumber();
		var color = Graphics.COLOR_GREEN;
		
		if (batteryChargeLevel < 50) {
			color = Graphics.COLOR_YELLOW;
		}
		if (batteryChargeLevel < 25) {
			color = Graphics.COLOR_RED;
		}
		if (batteryChargeLevel < 10) {
			color = Graphics.COLOR_DK_RED;
		}
		
		if(inLowPower && canBurnIn) {
        } else {
			dc.setColor(color, Graphics.COLOR_TRANSPARENT);
			dc.drawRoundedRectangle(self.dipX, self.dipY, self.dipLength, self.dipHeight, 2);	//Main battery body
			dc.drawRectangle(self.dipX + 1, self.dipY + 1, self.dipLength - 2, self.dipHeight -2);		// Inner frame
			dc.fillRoundedRectangle(self.noseCapX, self.noseCapY, 5, self.noseCapHeight, 2);		// Nose Cap
			dc.fillRectangle(self.dipX + 2, self.dipY + 2, chargeLevelFill, self.dipHeight -4);		// Charge Level
		}
		dc.clear();
	}
	
	function onEnterSleep() {
        inLowPower=true;
    }
    
    // This method is called when the device exits sleep mode.
    function onExitSleep() {
        inLowPower=false;
    }
}