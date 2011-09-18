package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.utils.*;
	
	import flash.net.*;
	import flash.display.*;
	import flash.utils.*;
	
	public class Main extends Engine
	{
		public static const PINK:uint = 0xff3366;
		public static const BLACK:uint = 0x202020;
		public static const GREY:uint = 0x787878;
		public static const WHITE:uint = 0xEEEEEE;
		
		public static var touchscreen:Boolean = false;
		public static var expoMode:Boolean = false;
		
		public static const SAVEFILE_VERSION:uint = 1;
		
		public static const so:SharedObject = SharedObject.getLocal("hearts", "/");
		
		
		[Embed(source = 'fonts/romance_fatal_pix.ttf', embedAsCFF="false", fontFamily = 'romance')]
		public static const ROMANCE_FONT:Class;
		[Embed(source = 'fonts/7x5.ttf', embedAsCFF="false", fontFamily = '7x5')]
		public static const FONT:Class;
		
		public function Main ()
		{
			if (! so.data.levels) so.data.levels = {};
			if (! so.data.totalScore) so.data.totalScore = 0;
			
			Text.font = "7x5";
			Text.size = 8;
			Text.defaultColor = WHITE;
			//Text.defaultAntiAliasType = "advanced";
			Text.defaultSharpness = 400;
			Text.defaultThickness = -400;
			
			Level.loadLevels();
			
			super(120, 120, 60, true);
			FP.screen.color = 0x202020;
			FP.screen.scale = 4;
			
			//FP.console.enable();
			//FP.console.toggleKey = Key.SPACE;
			
			try {
				var MultiTouch:Class = getDefinitionByName("flash.ui.Multitouch") as Class;
				if (MultiTouch.supportsTouchEvents) {
					touchscreen = true;
					MultiTouch.inputMode = "none";
				}
			} catch (e:Error){}
		}
		
		public override function init (): void
		{
			sitelock(["draknek.org", "flashgamelicense.com"]);
			
			super.init();
			
			Audio.init(this);
			
			Logger.connect(this);
			
			var devMode:Boolean = false;
			
			if (Logger.isLocal && ! touchscreen && ! expoMode) devMode = true;
			
			FP.world = devMode ? new Menu : new Intro;
		}
		
		public override function update (): void
		{
			if (Input.mousePressed) {
				hadMouseDown = true;
			}
			
			super.update();
			
			Audio.update();
			
			if (Input.mouseReleased) {
				hadMouseDown = false;
				ignoreNextAction = false;
			}
		}
		
		public override function setStageProperties():void
		{
			super.setStageProperties();
			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			
			if (touchscreen || expoMode) {
				try {
					stage.displayState = StageDisplayState.FULL_SCREEN;
				} catch (e:Error) {
				
				}
			}
		}
		
		public static function get inputHover ():Boolean
		{
			if (touchscreen) {
				if (ignoreNextAction) {
					return false;
				}
				
				return Input.mouseDown || Input.mouseReleased;
			} else {
				return true;
			}
		}
		
		public static function get inputClick ():Boolean
		{
			if (touchscreen) {
				if (ignoreNextAction || ! hadMouseDown) {
					return false;
				}
				
				return Input.mouseReleased;
			} else {
				return Input.mousePressed;
			}
		}
		
		public static function get anyInput ():Boolean
		{
			if (touchscreen) {
				ignoreNextAction = true;
				return Input.mousePressed;
			} else {
				return Input.mousePressed || Input.pressed(Key.ANY);
			}
		}
		
		private static var ignoreNextAction:Boolean = false;
		private static var hadMouseDown:Boolean = false;
		
		public function sitelock (allowed:*):Boolean
		{
			var url:String = FP.stage.loaderInfo.url;
			
			if (! url) return true;
			
			var startCheck:int = url.indexOf('://' ) + 3;
			
			if (url.substr(0, 28) == 'file:///accounts/1000/shared') {
				touchscreen = true;
			}
			
			if (url.substr(0, startCheck) == 'file://') return true;
			if (url.substr(0, startCheck) == 'app://') {
				touchscreen = true;
				return true;
			}
			
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

