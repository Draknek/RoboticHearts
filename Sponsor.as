package
{
	import com.newgrounds.*;
	import com.newgrounds.components.*;
	
	import flash.display.*;
	
	import net.flashpunk.*;
	
	public class Sponsor
	{
		public static var container:DisplayObjectContainer;
		
		public static var stageHeight:Number;
		
		public static function init (stage:Stage):void
		{
			API.connect(stage, Secret.NG_API_ID, Secret.NG_KEY);
			stageHeight = stage.stageHeight;
			Scores.init();
		}
		
		public static function testMedals ():void
		{
			var medal:Medal = API.getMedal("Young love");
			
			showMedal(medal);
		}
		
		private static function showMedal (medal:Medal):void
		{
			var size:int = 50;
			var border:int = 4;
			size += border*2;
			
			var sprite:Sprite = new Sprite;
			
			sprite.graphics.beginFill(Main.GREY);
			sprite.graphics.drawRect(0, -size, size, size);
			sprite.graphics.endFill();
			
			sprite.alpha = 0;
			
			sprite.x = border;
			sprite.y = stageHeight - border;
			
			var medalImage: Sprite = medal.attachIcon(sprite);
			
			medalImage.x = border;
			medalImage.y = -size + border;
			
			container.addChild(sprite);
			
			FP.tween(sprite, {alpha: 1}, 30);
			FP.tween(sprite, {alpha: 0}, 30, {delay: 120, complete: function ():void {
				container.removeChild(sprite);
			}});
			
		}
		
		/*private static function testMedal1 ():Boolean
		{
			for (var i:int = 0; i < 13; i++) {
				
			}
		}
		
		private static function testCompletion (i:int) {
			
		}*/
		
		public static function createAd():DisplayObject {
			//if (! API.connected) return null;
			
			return new FlashAd();
		}
	}
}

