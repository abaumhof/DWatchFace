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
	
	function initialize() {
		var dictionary = {
			:identifier => "BatteryHelper"
		};
		
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
		
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		dc.drawRoundedRectangle(self.dipX, self.dipY, self.dipLength, self.dipHeight, 2);	//Main battery body
		dc.drawRectangle(self.dipX + 1, self.dipY + 1, self.dipLength - 2, self.dipHeight -2);		// Inner frame
		dc.fillRoundedRectangle(self.noseCapX, self.noseCapY, 5, self.noseCapHeight, 2);		// Nose Cap
		dc.fillRectangle(self.dipX + 2, self.dipY + 2, chargeLevelFill, self.dipHeight -4);		// Charge Level
		
		dc.clear();
	}
}