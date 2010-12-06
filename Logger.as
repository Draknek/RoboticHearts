package
{
	import flash.display.*;
	import net.flashpunk.*;
	import SWFStats.*;
	import flash.system.Security;

	public class Logger
	{
		public static function connect (obj: DisplayObjectContainer): void
		{
			Log.View(1401, "0a6c8f42570e464e", obj.stage.loaderInfo.loaderURL);
		}
		
		public static function startLevel (id:int): void
		{
			Log.CustomMetric("started"+id);
			Log.LevelCounterMetric("started", id);
		}

		public static function endLevel (id:int): void
		{
			Log.CustomMetric("completed"+id);
			
			Log.LevelCounterMetric("completed", id);
			
			Log.LevelAverageMetric("time", id, Level(FP.world).time);
			Log.LevelAverageMetric("clicks", id, Level(FP.world).clicks);
		}

		public static function click (): void
		{
			var id:int = Level(FP.world).id;
			
			Log.LevelCounterMetric("clickcounter", id);
		}
		
	}
}


