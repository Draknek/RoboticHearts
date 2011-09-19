package
{
	import flash.display.*;
	import flash.geom.*;
	
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	
	public class Graph
	{
		[Embed(source="fonts/3x5.png")]
		public static const NUMBER_FONT:Class;
		
		public static function makeGraph (dataIn:Object, params:Object): BitmapData
		{
			if (! dataIn) return null;
			
			var yourClicks:int = params.highlight;
			
			var data:Object = {};
			
			var key:String;
			
			for (key in dataIn) {
				data[key] = dataIn[key];
			}
			
			var i:int
			
			const MAX_WIDTH:int = params.maxX || int.MAX_VALUE;
			
			var overMax:Boolean = false;
			
			var maxClicks:int = 0;
			var maxHeight:int = 1;
			
			for (key in data) {
				if (! params.show0 && key == "0") continue;
				
				if (int(key) > MAX_WIDTH) {
					data[MAX_WIDTH] = int(data[key]) + int(data[MAX_WIDTH]);
					delete data[key];
					key = String(MAX_WIDTH);
					overMax = true;
				}
				
				if (int(key) > maxClicks) maxClicks = int(key);
				if (data[key] > maxHeight) maxHeight = data[key];
			}
			
			var width:int = Math.ceil(maxClicks/10)*10;
			if (width < params.minX) width = params.minX;
			var height:int = params.height;
			
			var offsetX:int = 0;
			
			if (params.show0) {
				offsetX = 2;
			}
			
			FP.rect.x = 1;
			FP.rect.y = 1;
			FP.rect.width = width + params.extraWidth + 4 + offsetX;
			FP.rect.height = height + 2 + 8;
			
			if (overMax) FP.rect.width += 4;
			
			var bitmap:BitmapData = new BitmapData(FP.rect.width + 2, FP.rect.height + 2, false, Main.BLACK);
			
			//bitmap.fillRect(FP.rect, Main.BLACK);
			
			FP.rect.width = 1;
			
			var scale:Number = height / maxHeight;
			
			if (scale > 4) scale = 4;
			
			for (i = params.show0 ? 0 : 1; i <= maxClicks; i++) {
				var c:uint = Main.WHITE;
				
				if (i == yourClicks) {
					c = Main.PINK;
				}
				
				FP.rect.height = Math.ceil(data[i] * scale);
				FP.rect.x = i + 1 + offsetX;
				FP.rect.y = height + 2 - FP.rect.height;
				
				bitmap.fillRect(FP.rect, c);
			}
			
			FP.rect.x = (params.show0 ? 1 : 2) + offsetX;
			FP.rect.width = width + (params.show0 ? 1 : 0);
			FP.rect.y = height + 2;
			FP.rect.height = 1;
			
			bitmap.fillRect(FP.rect, Main.GREY);
			
			var scaleX:int = params.scale || 1;
			var markerX:int = params.markers || 10;
			
			var numbers:Spritemap = new Spritemap(NUMBER_FONT, 3, 5);
			
			numbers.color = Main.WHITE;
			
			for (i = params.show0 ? 0 : markerX/scaleX; i <= width; i += markerX/scaleX) {
				bitmap.setPixel32(i + 1 + offsetX, height + 3, Main.GREY);
				
				FP.point.x = i + offsetX;
				FP.point.y = height + 5;
				
				var val:int = i * scaleX;
				
				drawNumber(val, bitmap, FP.point);
				
				if (overMax && i == MAX_WIDTH) {
					FP.point.x = i + 6 + offsetX;
					numbers.frame = 10;
					numbers.render(bitmap, FP.point, FP.zero);
				}
			}
			
			//var text:Text = new Text("Clicks", 0, height + 3);
			
			//text.x = (bitmap.width - text.width)*0.5 + 1;
			
			//text.render(bitmap, FP.zero, FP.zero);
			
			return bitmap;
		}
		
		public static function drawNumber (value:int, target:BitmapData = null, point:Point = null):BitmapData
		{
			var s:String = value.toString();
			
			var w:int = 3;
			var h:int = 5;
			
			var numbers:Spritemap = new Spritemap(NUMBER_FONT, 3, 5);
			
			var fullWidth:int = (w+1)*s.length - 1;
			
			if (! target) {
				target = new BitmapData(fullWidth, h, true, 0x0);
			}
			
			if (point) {
				point.x -= fullWidth*0.5 - 2;
			} else {
				point = FP.point;
				point.x = 0;
				point.y = 0;
			}
			
			point.x += fullWidth - w;
			
			for (var i:int = 0; i < s.length; i++) {
				var digit:int = value % 10;
				
				value /= 10;
				
				numbers.frame = digit;
				numbers.render(target, FP.point, FP.zero);
				
				FP.point.x -= w + 1;
			}
			
			return target;
		}
	}
}
