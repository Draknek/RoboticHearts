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
		
		public static function startLevel (id:int): void
		{
			if (isLocal) return;
			
			Log.LevelCounterMetric("started", id);
		}

		public static function restartLevel (id:int): void
		{
			if (isLocal) return;
			
			Log.LevelCounterMetric("restarted", id);
		}

		public static function endLevel (id:int): void
		{
			if (isLocal) return;
			
			Log.LevelCounterMetric("completed", id);
			
			Log.LevelAverageMetric("time", id, Level(FP.world).time);
			Log.LevelAverageMetric("clicks", id, Level(FP.world).clicks);
		}

		public static function alert (message:String): void
		{
			var hash:String = MD5.hash(message + Secret.SALT);
			
			var url:String = "http://www.draknek.org/include/alert.php?message=" + escape(message) + "&hash=" + escape(hash);
			
			var request:URLRequest = new URLRequest(url);
			
			var loader:URLLoader = new URLLoader(request);
			
			trace(message);
		}
	}
}


