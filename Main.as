package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.utils.*;
	import net.flashpunk.utils.Input;
	
	import flash.net.*;
	import flash.display.*;
	import flash.events.*;
	import flash.ui.*;
	import flash.utils.*;
	
	import net.jpauclair.*;
	
	public class Main extends Engine
	{
		public static const PINK:uint = 0xff3366;
		public static const BLACK:uint = 0x202020;
		public static const GREY:uint = 0x787878;
		public static const WHITE:uint = 0xEEEEEE;
		
		public static var touchscreen:Boolean = false;
		public static var expoMode:Boolean = false;
		public static var debug:Boolean = false;
		
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
			
			try {
				var MultiTouch:Class = getDefinitionByName("flash.ui.Multitouch") as Class;
				if (MultiTouch.supportsTouchEvents) {
					touchscreen = true;
					MultiTouch.inputMode = "none";
				}
			} catch (e:Error){}
			
			Text.font = "7x5";
			Text.size = 8;
			Text.defaultColor = WHITE;
			//Text.defaultAntiAliasType = "advanced";
			Text.defaultSharpness = 400;
			Text.defaultThickness = -400;
			
			Level.loadLevels();

			var w:int;
			var h:int;
			
			var targetW:int = 120;
			var targetH:int = 100;
			
			var scale:int = 4;
			
			if (touchscreen || expoMode) {
				try {
					Preloader.stage.displayState = StageDisplayState.FULL_SCREEN;
				} catch (e:Error) {}
				
				w = Preloader.stage.fullScreenWidth;
				h = Preloader.stage.fullScreenHeight;
			} else {
				w = Preloader.stage.stageWidth;
				h = Preloader.stage.stageHeight;
			}
			
			var sizeX:Number = w / targetW;
			var sizeY:Number = h / targetH;
		
			if (sizeX > sizeY) {
				scale = int(sizeY);
			} else {
				scale = int(sizeX);
			}
	
			w = Math.ceil(w / scale);
			h = Math.ceil(h / scale);
			
			trace(w+","+h);
			
			super(w, h, 60, true);
			FP.screen.color = 0x202020;
			FP.screen.scale = scale;
			
			if (debug) {
				FP.console.enable();
				//FP.console.toggleKey = Key.SPACE;
			}
		}
		
		public override function init (): void
		{
			touchscreen = true; // testing
			
			if (debug) {
				try {
					var profiler:* = new FlashPreloadProfiler();
					profiler.y = 32;
					addChild(profiler);
				}
				catch (e:Error) {}
			}
			
			sitelock(["draknek.org", "draknek.dev", "flashgamelicense.com"]);
			
			super.init();
			
			try {
				Audio.init(this);
			} catch (e:Error) {FP.log("audio");}
			
			try {
				Logger.connect(this);
			} catch (e:Error) {FP.log("logger");}
			
			var devMode:Boolean = false;
			
			FP.stage.addEventListener(KeyboardEvent.KEY_DOWN, extraKeyListener);
			
			if (Logger.isLocal && ! touchscreen) devMode = true;
			
			FP.world = (devMode || expoMode) ? new Menu : new Intro;
		}
		
		public override function update (): void
		{
			if (Input.mousePressed) {
				hadMouseDown = true;
			}
			
			if (Input.mouseDown) {
				Main.mouseX = FP.screen.mouseX;
				Main.mouseY = FP.screen.mouseY;
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
			
			if (touchscreen || expoMode) {
				try {
					stage.displayState = StageDisplayState.FULL_SCREEN;
				} catch (e:Error) {
					stage.align = StageAlign.TOP;
					stage.scaleMode = StageScaleMode.SHOW_ALL;
				}
			} else {
				stage.align = StageAlign.TOP;
				stage.scaleMode = StageScaleMode.SHOW_ALL;
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
				if (Input.mousePressed) {
					ignoreNextAction = true;
				}
				return Input.mousePressed;
			} else {
				return Input.mousePressed || Input.pressed(Key.ANY);
			}
		}
		
		private static var ignoreNextAction:Boolean = false;
		private static var hadMouseDown:Boolean = false;
		
		public static var mouseX:Number = 0;
		public static var mouseY:Number = 0;
		
		public static function resetPlayerData ():void
		{
			Main.so.data.levels = {};
			Main.so.data.lastPlayed = null;
			Main.so.data.totalScore = 0;
			Main.so.flush();
		}
		
		public function sitelock (allowed:*):Boolean
		{
			var url:String = FP.stage.loaderInfo.url;
			
			if (! url) return true;
			
			var startCheck:int = url.indexOf('://' ) + 3;
			
			if (url.substr(0, 28) == 'file:///accounts/1000/shared') {
				Text.defaultAntiAliasType = "advanced";
				touchscreen = true;
			}
			
			if (url.substr(0, startCheck) == 'file://') return true;
			if (url.substr(0, startCheck) == 'app://') {
				touchscreen = true;
				return true;
			}
			
			if (url.substr(0, startCheck) != 'http://') return true;
			
			var domainLen:int = url.indexOf('/', startCheck) - startCheck;
			var host:String = url.substr(startCheck, domainLen);
			
			if (allowed is String) allowed = [allowed];
			for each (var d:String in allowed)
			{
				if (host.substr(-d.length, d.length) == d) return true;
			}
			
			if (touchscreen) return true;
			
			parent.removeChild(this);
			throw new Error("Error: this game is sitelocked");
			
			return false;
		}
		
		private function extraKeyListener(event:KeyboardEvent):void
		{
			try {
			const BACK:uint   = ("BACK" in Keyboard)   ? Keyboard["BACK"]   : 0;
			const MENU:uint   = ("MENU" in Keyboard)   ? Keyboard["MENU"]   : 0;
			const SEARCH:uint = ("SEARCH" in Keyboard) ? Keyboard["SEARCH"] : 0;
			
			if(event.keyCode == BACK || event.keyCode == MENU) {
				if (! (FP.world is Menu)) {
					FP.world = new Menu;
				} else if (Menu(FP.world).backButton.disabled) {
					return;
				} else {
					Menu(FP.world).back();
				}
			} else if(event.keyCode == SEARCH) {
				
			} else {
				return;
			}
			
			event.preventDefault();
			event.stopImmediatePropagation();
			} catch (e:Error) { FP.log(e + ": key listener"); }
		}
	}
}

