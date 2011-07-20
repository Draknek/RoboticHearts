package
{
	import flash.display.*;
	import net.flashpunk.*;
	import FGL.GameTracker.*;
	import Playtomic.*;
	import flash.system.Security;
	import flash.events.*;
	import flash.net.*;
	
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;

	public class Logger
	{
		[Embed(source="levels/stats.json", mimeType="application/octet-stream")]
		public static const STATS:Class;
		
		public static const HOST:String = "draknek.dev";
		
		public static const DB:String = "http://" + HOST + "/games/hearts/db/";
		
		public static var isLocal:Boolean = false;
		
		public static var uid:String;
		
		public static var clickStats:Object = {};
		public static var scoreStats:Object = {};
		
		private static var FGL:GameTracker;
		
		public static function magic (query:String, f:Function = null): void
		{
			var request:URLRequest = new URLRequest(DB + query);
			
			function doComplete ():void
			{
				f(loader.data);
			}
			
			function nullErrorHandler ():void {}

			var loader:URLLoader = new URLLoader();
			
			if (f != null) {
				loader.addEventListener(Event.COMPLETE, doComplete);
			}
			
			if (! isLocal) {
				loader.addEventListener(IOErrorEvent.IO_ERROR, nullErrorHandler);
			}
			
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
		
		public static function getScores (): void
		{
			function unJSON (dataString:*):void
			{
				clickStats = JSON.decode(dataString);
				Main.so.data.stats = clickStats;
				Main.so.data.lastStatsDownload = (new Date()).getTime();
			}
			
			magic("get.php", unJSON);
		}
		
		public static function getScoreStats (): void
		{
			function unJSON (dataString:*):void
			{
				scoreStats = JSON.decode(dataString);
			}
			
			magic("get.php?scorestats=1", unJSON);
		}
		
		public static function connect (obj: DisplayObjectContainer): void
		{
			if (Main.so.data.stats) {
				clickStats = Main.so.data.stats;
			} else {
				clickStats = JSON.decode(new STATS);
			}
			
			if (Main.so.data.uid) {
				uid = Main.so.data.uid;
			} else {
				getUID();
			}
			
			getScoreStats();
			
			var now:Number = (new Date()).getTime();
			
			var lastStatsDownload:Number = Main.so.data.lastStatsDownload;
			if (! lastStatsDownload) lastStatsDownload = 0;
			
			if (now - lastStatsDownload > 1000 * 60 * 60 * 24) {			
				getScores();
			}
			
			isLocal = (obj.stage.loaderInfo.loaderURL.substr(0, 7) == 'file://');
			
			if (isLocal) return;
			
			FGL = new GameTracker();
			
			FGL.beginGame();
			
			Log.View(Secret.PLAYTOMIC_SWFID, Secret.PLAYTOMIC_GUID, obj.stage.loaderInfo.loaderURL);
		}
		
		public static function startLevel (id:int, mode:String): void
		{
			if (isLocal) return;
			
			Log.LevelCounterMetric("started", l(id, mode));
			
			FGL.beginLevel(id, Main.so.data.totalScore);
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
			
			FGL.endLevel(Main.so.data.totalScore, null, Level(FP.world).clicks + " clicks (" + Level(FP.world).minClicks + " min)");
			
			FGL.alert(Main.so.data.totalScore, null, "Completed level " + (id + 1) + ": " + Level(FP.world).clicks + " clicks (" + Level(FP.world).minClicks + " min)");
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
			
			FGL.alert(Main.so.data.totalScore, null, message);
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


