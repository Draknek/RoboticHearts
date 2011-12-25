package
{
	import flash.display.*;
	import net.flashpunk.*;
	import FGL.GameTracker.*;
	import Playtomic.*;
	import flash.system.Security;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;

	public class Logger
	{
		[Embed(source="levels/stats.json", mimeType="application/octet-stream")]
		public static const STATS:Class;
		
		public static var DB:String;
		
		public static var isLocal:Boolean = false;
		
		public static var uid:String;
		
		public static var clickStats:Object = {};
		public static var scoreStats:Object = {};
		
		// h: before redoing levels to match screen size
		// i: after redoing levels, but reserved for pretend stats
		// j: actual players
		public static const VERSION:String = "j";
		
		private static var FGL:GameTracker;
		
		private static var queueA:Array = [];
		private static var httpActive:Boolean = false;
		
		public static function magic (query:String, f:Function = null): void
		{
			if (f != null) {
				queueA.push({q: query, f: f});
			} else {
				Main.so.data.httpQueue.push(query);
			}
			
			if (! httpActive) {
				doQueuedMagic();
			}
		}
		
		private static function doQueuedMagic (): void
		{
			var query:String;
			var f:Function;
			
			var queue:Array;
			
			if (queueA.length) {
				queue = queueA;
				query = queue[0].q;
				f = queue[0].f;
			} else if (Main.so.data.httpQueue.length) {
				queue = Main.so.data.httpQueue;
				query = queue[0];
			} else {
				httpActive = false;
				return;
			}
			
			httpActive = true;
			
			var request:URLRequest = new URLRequest(DB + query);
			
			function doComplete ():void
			{
				if (f != null) {
					try {
						f(loader.data);
					} catch (e:Error) {
						httpActive = false;
				
						trace("Callback raised exception: " + e + " (Query: " + query + ")");
						
						return;
					}
				}
				
				queue.shift();
				
				doQueuedMagic();
			}
			
			function errorHandler ():void {
				httpActive = false;
				
				trace("Query failed: " + query);
			}

			var loader:URLLoader = new URLLoader();
			
			loader.addEventListener(Event.COMPLETE, doComplete);
			
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			loader.load(request);
		}
		
		public static function getUID (): void
		{
			function setUID (data:*):void {
				var i:int = data;
				
				if (! i) {
					throw new Error("UID not set");
				}
				
				uid = data;
				Main.so.data.uid = uid;
				Main.so.flush();
			}
			
			var host:String = FP.stage.loaderInfo.url;
			
			if (! host || host.substr(0,4) != 'http') {
				host = Capabilities.manufacturer + " -- " + Capabilities.os;
			}
			
			magic("get.php?newuser=1&version=" + VERSION + "&host=" + escape(host), setUID);
		}
		
		public static function getScores (): void
		{
			function unJSON (dataString:*):void
			{
				clickStats = JSON.decode(dataString);
				Main.so.data.stats = clickStats;
				Main.so.data.lastStatsDownload = (new Date()).getTime();
				
				updateBest();
			}
			
			magic("get.php?getbest=1&version=" + VERSION, unJSON);
		}
		
		public static function getScoreStats (): void
		{
			function unJSON (dataString:*):void
			{
				scoreStats = JSON.decode(dataString);
			}
			
			magic("get.php?scorestats=1&version=" + VERSION, unJSON);
		}
		
		private static function updateBest ():void
		{
			if (! clickStats['best']) return;
			
			for (var i:int = 0; i < Level.levelPacks["normal"].md5.length; i++) {
				var md5:String = Level.levelPacks["normal"].md5[i];
				
				if (clickStats['best'].hasOwnProperty(md5)) {
					Level.levelPacks["normal"].minClicksArray[i] = int(clickStats['best'][md5]);
				}
			}
		}
		
		public static function connect (obj: DisplayObjectContainer): void
		{
			isLocal = (obj.stage.loaderInfo.loaderURL.substr(0, 7) == 'file://');
			
			var host:String = /*isLocal ? "draknek.dev/games/hearts/db" :*/ "hearts.draknek.org";
			
			DB = "http://" + host + "/";
			
			if (Main.so.data.stats) {
				clickStats = Main.so.data.stats;
			} else {
				clickStats = JSON.decode(new STATS);
			}
			
			updateBest();
			
			if (Main.so.data.uid) {
				uid = Main.so.data.uid;
			} else {
				getUID();
			}
			
			//getScoreStats();
			
			var now:Number = (new Date()).getTime();
		
			var lastStatsDownload:Number = Main.so.data.lastStatsDownload;
			if (! lastStatsDownload) lastStatsDownload = 0;
		
			if (now - lastStatsDownload > 1000 * 60 * 60 * 24) {			
				getScores();
			}
			
			Scores.init();
			
			if (isLocal) return;
			
			/*FGL = new GameTracker();
			
			FGL.beginGame();
			
			//Log.View(Secret.PLAYTOMIC_SWFID, Secret.PLAYTOMIC_GUID, obj.stage.loaderInfo.loaderURL);*/
		}
		
		public static function startLevel (id:int, mode:String): void
		{
			if (isLocal) return;
			
			/*Log.LevelCounterMetric("started", l(id, mode));
			
			FGL.beginLevel(id, Main.so.data.totalScore);*/
		}

		public static function restartLevel (id:int, mode:String): void
		{
			if (isLocal) return;
			
			//Log.LevelCounterMetric("restarted", l(id, mode));
		}

		public static function endLevel (id:int, mode:String): void
		{
			submitScore(id, mode);
			
			if (isLocal) return;
			
			/*Log.LevelCounterMetric("completed", l(id, mode));
			
			Log.LevelAverageMetric("time", l(id, mode), Level(FP.world).time);
			Log.LevelAverageMetric("clicks", l(id, mode), Level(FP.world).clicks);
			
			FGL.endLevel(Main.so.data.totalScore, null, Level(FP.world).clicks + " clicks (" + Level(FP.world).minClicks + " min)");
			
			FGL.alert(Main.so.data.totalScore, null, "Completed level " + (id + 1) + ": " + Level(FP.world).clicks + " clicks (" + Level(FP.world).minClicks + " min)");*/
		}
		
		public static function submitScore (id:int, mode:String): void
		{
			var level:Level = Level(FP.world);
			
			var levelMD5:String = MD5.hashBytes(level.data);
			
			var clicks:int = level.clicks;
			
			if (! clickStats[levelMD5]) {
				clickStats[levelMD5] = {};
			}
			
			if (clickStats[levelMD5][clicks]) clickStats[levelMD5][clicks]++;
			else clickStats[levelMD5][clicks] = 1;
			
			Main.so.data.stats = clickStats;
			
			Main.so.flush();
			
			if (! uid) return;
			
			var solution:String = Secret2.encodeSolution(level.undoStack);
			
			magic("submit.php?uid=" + uid + "&lvl=" + levelMD5 + "&clicks=" + clicks + "&cogs=" + solution + "&version=" + VERSION);
		}
		
		public static function alert (message:String): void
		{
			var hash:String = MD5.hash(message + Secret.SALT);
			
			var url:String = "http://www.draknek.org/include/alert.php?message=" + escape(message) + "&hash=" + escape(hash);
			
			var request:URLRequest = new URLRequest(url);
			
			var loader:URLLoader = new URLLoader(request);
			
			trace(message);
			
			if (isLocal) return;
			
			//FGL.alert(Main.so.data.totalScore, null, message);
		}
		
		private static function l (id:int, mode:String):String
		{
			var s:String = VERSION;
			
			if (mode == "perfection") s += "*";
			
			if (id < 10) s += "0";
			
			s += id;
			
			return s;
		}
	}
}


