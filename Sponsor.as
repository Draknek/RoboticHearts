package
{
	import com.newgrounds.*;
	import com.newgrounds.components.*;
	
	import flash.display.*;
	
	import net.flashpunk.*;
	
	public class Sponsor
	{
		public static function init ():void
		{
			API.connect(FP.stage, Secret.NG_API_ID, Secret.NG_KEY);
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
			sprite.y = FP.stage.stageHeight - border;
			
			var medalImage: Sprite = medal.attachIcon(sprite);
			
			medalImage.x = border;
			medalImage.y = -size + border;
			
			FP.engine.addChild(sprite);
			
			FP.tween(sprite, {alpha: 1}, 30);
			FP.tween(sprite, {alpha: 0}, 30, {delay: 120, complete: function ():void {
				FP.engine.removeChild(sprite);
			}});
			
		}
		
		/*private static function testMedal1 ():Boolean
		{
			for (var i:int = 0; i < 13; i++) {
				
			}
		}
		
		private static function testCompletion (i:int) {
			
		}*/
	}
}

