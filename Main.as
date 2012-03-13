package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.utils.*;
	import net.flashpunk.utils.Input;
	
	import flash.net.*;
	import flash.text.*;
	import flash.display.*;
	import flash.events.*;
	import flash.ui.*;
	import flash.utils.*;
	import flash.system.*;
	import flash.desktop.*;
	
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
		public static var isAndroid:Boolean = false;
		public static var isIOS:Boolean = false;
		public static var isPlaybook:Boolean = false;
		public static var buttonTweak:Boolean = true;
		
		public static const SAVEFILE_VERSION:uint = 2;
		
		public static var clicks_string:String = "Clicks";
		public static var clicks_string_lower:String;
		
		public static const so:SharedObject = SharedObject.getLocal("hearts", "/");
		
		
		[Embed(source = 'fonts/romance_fatal_pix.ttf', embedAsCFF="false", fontFamily = 'romance')]
		public static const ROMANCE_FONT:Class;
		[Embed(source = 'fonts/7x5.ttf', embedAsCFF="false", fontFamily = '7x5')]
		public static const FONT:Class;
		
		public function Main ()
		{
			if (Capabilities.manufacturer.toLowerCase().indexOf("ios") != -1) {
				isIOS = true;
				touchscreen = true;
			}
			else if (Capabilities.manufacturer.toLowerCase().indexOf("android") >= 0) {
				isAndroid = true;
				touchscreen = true;
			} else if (Capabilities.os.indexOf("QNX") >= 0) {
				isPlaybook = true;
				touchscreen = true;
			}
			
			if (! so.data.levels) so.data.levels = {};
			if (! so.data.totalScore) so.data.totalScore = 0;
			if (! so.data.httpQueue) so.data.httpQueue = [];
			
			/*try {
				var MultiTouch:Class = getDefinitionByName("flash.ui.Multitouch") as Class;
				if (MultiTouch.supportsTouchEvents) {
					touchscreen = true;
					MultiTouch.inputMode = "none";
				}
			} catch (e:Error){}*/
			
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
			
			if (Preloader.resTest) {
				Preloader.stage.scaleMode = StageScaleMode.NO_SCALE;
			}
			
			if (touchscreen || expoMode) {
				try {
					Preloader.stage.displayState = StageDisplayState.FULL_SCREEN;
				} catch (e:Error) {}
				
				w = Preloader.stage.fullScreenWidth;
				h = Preloader.stage.fullScreenHeight;
				
				if (isAndroid && w < h) {
					var tmp:int = w;
					w = h;
					h = tmp;
				}
			} else {
				w = Preloader.stage.stageWidth;
				h = Preloader.stage.stageHeight;
			}
			
			trace(w+","+h);
			
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
			
			Sponsor.container = this;
		}
		
		public override function init (): void
		{
			if (isIOS) {
				try {
					var StageOrientation:Class = getDefinitionByName("flash.display.StageOrientation") as Class;
					var StageOrientationEvent:Class = getDefinitionByName("flash.events.StageOrientationEvent") as Class;
					var startOrientation:String = FP.stage["orientation"];
					if (startOrientation == StageOrientation.DEFAULT || startOrientation == StageOrientation.UPSIDE_DOWN)
					{
						FP.stage["setOrientation"](StageOrientation.ROTATED_RIGHT);
					}
					else
					{
						FP.stage["setOrientation"](startOrientation);
					}

					FP.stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGING, orientationChangeListener);
				} catch (e:Error){}
			}

			//touchscreen = true; // testing
			
			if (touchscreen) {
				clicks_string = "Taps";
			}
			
			clicks_string_lower = clicks_string.toLowerCase();
			
			if (debug) {
				try {
					var profiler:* = new FlashPreloadProfiler();
					profiler.y = 32;
					addChild(profiler);
				}
				catch (e:Error) {}
			}
			
			sitelock(["draknek.org", "draknek.dev"]);
			
			super.init();
			
			try {
				Audio.init(this);
			} catch (e:Error) {FP.log("audio");}
			
			try {
				Logger.connect(this);
			} catch (e:Error) {FP.log("logger");}
			
			var devMode:Boolean = false;
			
			FP.stage.addEventListener(KeyboardEvent.KEY_DOWN, extraKeyListener);
			
			if (touchscreen) {
				buttonTweak = false;
			}
			
			if (buttonTweak) {
				FP.stage.addEventListener(MouseEvent.MOUSE_DOWN, extraMouseListener);
			}
			
			if (Logger.isLocal && ! touchscreen) devMode = true;
			
			contextMenu.clipboardMenu = true;
			contextMenu.clipboardItems.copy = true;
			contextMenu.clipboardItems.paste = true;
			contextMenu.clipboardItems.clear = true;

			addEventListener(Event.COPY, copyHandler);
			addEventListener(Event.PASTE, pasteHandler);
			addEventListener(Event.CLEAR, clearHandler);
			
			if (stage.loaderInfo.parameters && stage.loaderInfo.parameters.leveldata) {
				var dataString:String = stage.loaderInfo.parameters.leveldata;
				dataString = dataString.split(" ").join("+");
			}
			
			var data:ByteArray = null;
			
			try {
				data = Base64.decode(dataString);
			} catch (e:Error) {}
			
			FP.world = new Level(0, null, data);
			
			Audio.startMusic();
		}
		
		private static function copyHandler(event:Event):void 
		{
			var level:Level = FP.world as Level;
			
			if (level) {
				var data:String = Base64.encode(level.getWorldData());
				System.setClipboard("http://hearts.draknek.org/editor/?level=" + data);
			}
		}
		
		private static function pasteHandler(event:Event):void 
		{
			var clipboard:String = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT) as String;
			
			var level:Level = FP.world as Level;
			
			if (level) {
				var index:int = clipboard.indexOf('?');
				
				if (index == -1) {
					index = 0;
				} else {
					var index2:int = clipboard.indexOf('=', index);
					
					if (index2 == -1) {
						index += 1;
					} else {
						index = index2 + 1;
					}
				}
				
				var data:ByteArray = Base64.decode(clipboard.substring(index));
				level.setWorldData(data);
			}
		}
		
		private static function clearHandler(event:Event):void 
		{
			var level:Level = FP.world as Level;
			
			if (level) {
				level.editing = true;
				level.reset();
			}
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
			
			if (Input.pressed(Key.SPACE)) {
				//Sponsor.addAd();
			}
		}
		
		public override function setStageProperties():void
		{
			super.setStageProperties();
			
			if (Preloader.resTest) { return; }
			
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
				return Input.mousePressed || Input.pressed(Key.ANY);
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
			
			var link:TextField = makeHTMLText('This game is not authorised\nto play on this website.\n\n<a href="http://www.newgrounds.com/portal/view/585599">Play on Newgrounds here</a>\n\n<a href="http://www.draknek.org/games/hearts/?ref=2">Or buy for iOS or Android</a>', 32, WHITE, "a {color: #ff3366} a:hover {text-decoration:underline;}");
			
			link.x = (width - link.width) * 0.5;
			link.y = (height - link.height) * 0.5;
			
			parent.addChild(link);
			
			parent.removeChild(this);
			throw new Error("Error: this game is sitelocked");
			
			return false;
		}
		
		private function extraMouseListener(event:MouseEvent):void
		{
			if (! FP.world.active) return;
			
			var a:Array = [];
			
			FP.world.getType("button", a);
			
			for each (var b:Button in a) {
				if (b.callback == null || b.disabled) continue;
				
				var _x:Number = b.x;
				var _y:Number = b.y;
			
				if (b.noCamera) {
					_x += FP.camera.x;
					_y += FP.camera.y;
				}
			
				var over:Boolean = b.collidePoint(_x, _y, FP.world.mouseX, FP.world.mouseY);
				
				if (over) {
					b.callback();
				}
			}
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
		
		private function orientationChangeListener(e:*): void
		{
			if (e.afterOrientation == "default" || e.afterOrientation ==  "upsideDown")
			{
				e.preventDefault();
			}
		}
		
		public static function makeHTMLText (html:String, size:Number, color:uint, css:String): TextField
		{
			var ss:StyleSheet = new StyleSheet();
			ss.parseCSS(css);
			
			var textField:TextField = new TextField;
			
			textField.selectable = false;
			textField.mouseEnabled = true;
			
			textField.embedFonts = true;
			
			textField.multiline = true;
			
			textField.autoSize = "center";
			
			textField.textColor = color;
			
			var format:TextFormat = new TextFormat("7x5", size);
			format.align = "center";
			
			textField.defaultTextFormat = format;
			
			textField.htmlText = html;
			
			textField.styleSheet = ss;
			
			return textField;
		}

	}
}

