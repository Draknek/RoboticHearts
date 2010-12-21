package
{
	import net.flashpunk.*;
	
	[SWF(width = "384", height = "384", backgroundColor="#202020")]
	public class Main extends Engine
	{
		public static const PINK:uint = 0xff3366;
		public static const BLACK:uint = 0x202020;
		public static const GREY:uint = 0x787878;
		public static const WHITE:uint = 0xEEEEEE;
		
		public function Main ()
		{
			Level.loadLevels();
			
			super(96, 96, 60, true);
			FP.world = new Level();
			FP.screen.color = 0x202020;
			FP.screen.scale = 4;
		}
		
		public override function init (): void
		{
			sitelock("draknek.org");
			
			super.init();
			
			Logger.connect(this);
		}
		
		public function sitelock (allowed:*):Boolean
		{
			var url:String = FP.stage.loaderInfo.url;
			var startCheck:int = url.indexOf('://' ) + 3;
			
			if (url.substr(0, startCheck) == 'file://') return true;
			
			var domainLen:int = url.indexOf('/', startCheck) - startCheck;
			var host:String = url.substr(startCheck, domainLen);
			
			if (allowed is String) allowed = [allowed];
			for each (var d:String in allowed)
			{
				if (host.substr(-d.length, d.length) == d) return true;
			}
			
			parent.removeChild(this);
			throw new Error("Error: this game is sitelocked");
			
			return false;
		}
	}
}

