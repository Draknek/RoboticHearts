package
{
	import com.newgrounds.*;
	import com.newgrounds.components.MedalPopup;
	import com.newgrounds.components.FlashAd;
	
	import flash.display.*;
	import flash.utils.*;
	
	public class Sponsor
	{
		public static var container:DisplayObjectContainer;
		
		public static var stageHeight:Number;
		
		public static var medalPopup:DisplayObject;
		
		private static var medalNames:Array = [null, "Young love", "Heartbreak", "Those Robotic Hearts of His", "Robotic efficiency", "Perfectionist"];
		
		public static function init (stage:Stage):void
		{
			API.connect(stage, Secret.NG_API_ID, Secret.NG_KEY);
			stageHeight = stage.stageHeight;
		}
		
		public static function testMedals (final:Boolean = false):void
		{
			if (! (API.sessionId && API.sessionId != "0")) return;
			
			if (! medalPopup) {
				medalPopup = new MedalPopup;
				
				medalPopup.x = 8;
				medalPopup.y = container.stage.stageHeight - medalPopup.height - 8;
				
				container.addChild(medalPopup);
			}
			
			for (var i:int = 1; i < medalNames.length; i++) {
				var name:String = medalNames[i];
				
				var f:Function = Sponsor["testMedal"+i];
				
				var unlocked:Boolean = f();
				
				if (name == "Those Robotic Hearts of His" && ! final) unlocked = false;
				
				if (unlocked) {
					var medal:Medal = API.getMedal(name);
					
					if (! medal) continue;
					
					if (! medal.unlocked) {
						medal.unlock();
						//showMedal(medal);
					}
				}
			}
		}
		
		/*private static function showMedal (medal:Medal):void
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
			
		}*/
		
		private static function testMedal1 ():Boolean
		{
			return testCompletion(13);
		}
		
		private static function testMedal2 ():Boolean
		{
			return testCompletion(25);
		}
		
		private static function testMedal3 ():Boolean
		{
			return testCompletion(36);
		}
		
		private static function testMedal4 ():Boolean
		{
			return testPerfection(18);
		}
		
		private static function testMedal5 ():Boolean
		{
			return testPerfection(36);
		}
		
		private static function testCompletion (last:int):Boolean {
			var Level2:Class = getDefinitionByName("Level") as Class;
			var Main2:Class = getDefinitionByName("Main") as Class;
			
			for (var i:int = 0; i < last; i++) {
				var md5:String = Level2.levelPacks["normal"].md5[i];
				
				if (! Main2.so.data.levels[md5] || ! Main2.so.data.levels[md5].completed) return false;
			}
			
			return true;
		}
		
		private static function testPerfection (last:int):Boolean {
			var Level2:Class = getDefinitionByName("Level") as Class;
			var Main2:Class = getDefinitionByName("Main") as Class;
			
			for (var i:int = 0; i < last; i++) {
				var md5:String = Level2.levelPacks["normal"].md5[i];
				
				var minClicksMine:int = Level2.levelPacks["normal"].minClicksArray[i];
				
				if (! Main2.so.data.levels[md5]) return false;
				
				var minClicksTheirs:int = Main2.so.data.levels[md5].leastClicks;
				
				if (minClicksTheirs > minClicksMine) return false;
			}
			
			return true;
		}
		
		public static function createAd():DisplayObject {
			//if (! API.connected) return null;
			
			return new FlashAd();
		}
		
		public static function update():void {
			if (! API.connected) return;
			if (API.isNewgrounds) return;
			Preloader.mustClick = true;
		}
	}
}

