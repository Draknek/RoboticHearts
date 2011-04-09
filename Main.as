package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	
	import flash.net.*;
	import flash.display.*;
	
	public class Main extends Engine
	{
		public static const PINK:uint = 0xff3366;
		public static const BLACK:uint = 0x202020;
		public static const GREY:uint = 0x787878;
		public static const WHITE:uint = 0xEEEEEE;
		
		public static const SAVEFILE_VERSION:uint = 1;
		
		public static const so:SharedObject = SharedObject.getLocal("hearts", "/");
		
		public function Main ()
		{
			if (! so.data.levels) so.data.levels = {};
			
			Text.size = 8;
			
			Level.loadLevels();
			
			super(96, 96, 60, true);
			FP.screen.color = 0x202020;
			FP.screen.scale = 4;
			
			//FP.console.enable();
		}
		
		public override function init (): void
		{
			sitelock("draknek.org");
			
			super.init();
			
			Audio.init(this);
			
			Logger.connect(this);
			
			FP.world = Logger.isLocal ? new Menu : new Intro;
		}
		
		public override function update (): void
		{
			super.update();
			
			Audio.update();
		}
		
		public override function setStageProperties():void
		{
			super.setStageProperties();
			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
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

