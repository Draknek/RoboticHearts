package
{
	import flash.display.*;
	import net.flashpunk.*;
	import Playtomic.*;
	import flash.system.Security;
	import flash.events.*;
	import flash.net.*;
	
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;

	public class Logger
	{
		public static const DB:String = "http://www.draknek.org/games/hearts/db/";
		
		public static var isLocal:Boolean = false;
		
		public static var uid:String;
		
		private static function magic (query:String, f:Function = null): void
		{
			var request:URLRequest = new URLRequest(DB + query);
			
			function doComplete ():void
			{
				f(loader.data);
			}
			
			function errorHandler ():void {}

			var loader:URLLoader = new URLLoader();
			
			if (f != null) {
				loader.addEventListener(Event.COMPLETE, doComplete);
			}
			
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			loader.load(request);
		}
		
		public static function getUID (): void
		{
			function setUID (data:*):void {
				uid = data;
				Main.so.data.uid = uid;
				Main.so.flush();
			}
			
			magic("get.php?newuser=1", setUID);
		}
		
		public static function getScores (id:int, mode:String, f:Function): void
		{
			function unJSON (dataString:*):void
			{
				var dataObj:Object = JSON.decode(dataString);
				
				f(dataObj);
			}
			
			magic("get.php", unJSON);
		}
		
		public static function connect (obj: DisplayObjectContainer): void
		{
			if (Main.so.data.uid) {
				uid = Main.so.data.uid;
			} else {
				getUID();
			}
			
			isLocal = (obj.stage.loaderInfo.loaderURL.substr(0, 7) == 'file://');
			
			if (isLocal) return;
			
			Log.View(Secret.PLAYTOMIC_SWFID, Secret.PLAYTOMIC_GUID, obj.stage.loaderInfo.loaderURL);
		}
		
		public static function startLevel (id:int, mode:String): void
		{
			if (isLocal) return;
			
			Log.LevelCounterMetric("started", l(id, mode));
		}

		public static function restartLevel (id:int, mode:String): void
		{
			if (isLocal) return;
			
			Log.LevelCounterMetric("restarted", l(id, mode));
		}

		public static function endLevel (id:int, mode:String): void
		{
			submitScore(id, mode);
			
			if (isLocal) return;
			
			Log.LevelCounterMetric("completed", l(id, mode));
			
			Log.LevelAverageMetric("time", l(id, mode), Level(FP.world).time);
			Log.LevelAverageMetric("clicks", l(id, mode), Level(FP.world).clicks);
		}
		
		public static function submitScore (id:int, mode:String): void
		{
			if (! uid) return;
			
			var level:Level = Level(FP.world);
			
			var levelMD5:String = MD5.hashBytes(level.data);
			
			var clicks:int = Level(FP.world).clicks;
			
			var solution:String = Secret.encodeSolution(Level(FP.world).undoStack);
			
			magic("submit.php?uid=" + uid + "&lvl=" + levelMD5 + "&clicks=" + clicks + "&cogs=" + solution);
		}
		
		public static function alert (message:String): void
		{
			var hash:String = MD5.hash(message + Secret.SALT);
			
			var url:String = "http://www.draknek.org/include/alert.php?message=" + escape(message) + "&hash=" + escape(hash);
			
			var request:URLRequest = new URLRequest(url);
			
			var loader:URLLoader = new URLLoader(request);
			
			trace(message);
		}
		
		private static function l (id:int, mode:String):String
		{
			var s:String = "c";
			
			if (mode == "perfection") s += "*";
			
			if (id < 10) s += "0";
			
			s += id;
			
			return s;
		}
	}
}


