package
{
	/*import com.newgrounds.*;
	import com.newgrounds.components.MedalPopup;
	import com.newgrounds.components.FlashAd;*/
	
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
			
		}
		
		public static function testMedals (final:Boolean = false):void
		{
			
		}
		
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
			return null;
		}
		
		public static function update():void {
			
		}
	}
}

