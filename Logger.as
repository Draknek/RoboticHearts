package
{
	import flash.display.*;
	import net.flashpunk.*;
	import Playtomic.*;
	import flash.system.Security;
	import flash.net.*;
	
	import com.adobe.crypto.MD5;

	public class Logger
	{
		public static var isLocal:Boolean = false;
		
		public static function connect (obj: DisplayObjectContainer): void
		{
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
			if (isLocal) return;
			
			Log.LevelCounterMetric("completed", l(id, mode));
			
			Log.LevelAverageMetric("time", l(id, mode), Level(FP.world).time);
			Log.LevelAverageMetric("clicks", l(id, mode), Level(FP.world).clicks);
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


