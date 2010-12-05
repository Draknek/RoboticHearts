package
{
	import net.flashpunk.*;
	
	[SWF(width = "640", height = "480", backgroundColor="#202020")]
	public class Main extends Engine
	{
		public function Main () 
		{
			super(640, 480, 60, true);
			FP.world = new Level();
			FP.screen.color = 0x202020;
		}
		
		public override function init (): void
		{
			sitelock("draknek.org");
			
			super.init();
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

