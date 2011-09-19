package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import org.qrcode.QRCode;
	import org.qrcode.enum.*;
	
	import com.adobe.serialization.json.JSON;
	
	import flash.display.*;
	import flash.utils.*;
	import flash.text.*;
	
	public class QRCodeExport extends World
	{
		public var stringData:String;
		
		public function QRCodeExport (_outro:Boolean = false)
		{
			var a:Object = JSON.decode(new Logger.STATS);
			var b:Object = Main.so.data.stats;
			
			var data:ByteArray = new ByteArray;
			
			for (var i:int = 2; i < 36; i++) {
				var md5:String = Level.levelPacks["normal"].md5[i];
				
				var newClicks:Object = {}
				
				var l:int = 0;
				
				for (var key:String in b[md5]) {
					{//if (a[md5][key] != b[md5][key]) {
						l++;
						
						if (! a[md5][key]) a[md5][key] = 0;
						
						newClicks[key] = b[md5][key] //- a[md5][key];
					}
				}
				
				var max:int = 255;
				
				for (key in newClicks) {
					if (int(key) > max) {
						if (! newClicks[max]) {
							newClicks[max] = 0;
						} else {
							l--;
						}
						
						newClicks[max] += newClicks[key];
						
						delete newClicks[key];
					}
				}
				
				data.writeByte(l);
				
				for (key in newClicks) {
					data.writeByte(int(key));
					data.writeShort(newClicks[key]);
				}
			}
			
			data.compress();
			
			stringData = Base64.encode(data);
			
			pages = Math.ceil(Number(stringData.length) / MAXLEN);
			
			bitmap = new Bitmap;
			text = new TextField;
			var format:TextFormat = text.defaultTextFormat;
			format.color = 0xFFFFFF;
			format.size = 32;
			text.defaultTextFormat = format;
			bitmap.y = text.height + 5;
			
			FP.engine.addChild(text);
			FP.engine.addChild(bitmap);
			
			show(0);
		}
		
		private var bitmap:Bitmap;
		private var text:TextField;
		
		private var pages:int;
		
		private const MAXLEN:int = 200;
		
		private var page:int = 0;
		
		public override function update ():void
		{
			if (Input.pressed(Key.SPACE)) {
				page++;
				if (page >= pages) {
					FP.engine.removeChild(text);
					FP.engine.removeChild(bitmap);
					FP.world = new Menu;
					return;
				}
				show(page);
			}
		}
		
		public function show (i:int):void
		{
			text.text = (i+1) + " of " + pages;
			
			var qr:QRCode = new QRCode();//QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC);
			qr.encode(text.text + " - " + stringData.substr(i*MAXLEN, MAXLEN));
			
			bitmap.bitmapData = qr.bitmapData;
		}
	}
}
