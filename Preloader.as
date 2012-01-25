
package
{
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.getDefinitionByName;
	import flash.net.*;

	// iPhone: 480x320 => 160x107
	// iPad: 1024x768 => 147x110 (test with 735x550)
	// Browser: 600x480? => 150x120
	// Some Android: 800x480 => 200x120
	// Some Android: 320x240 => 160x120
	[SWF(width = "800", height = "480", backgroundColor="#202020")]
	public class Preloader extends Sprite
	{
		public static const resTest:Boolean = false;
		
		// Change these values
		public static var mustClick: Boolean = false;
		private static const mainClassName: String = "Main";
		
		private static const BG_COLOR:uint = 0x202020;
		private static const FG_COLOR:uint = 0xff3366;
		
		public static var stage:Stage;
		
		public static var ad:Sprite;
		
		private static var play:SimpleButton;
		
		// Ignore everything else
		
		
		
		private var progressBar: Shape;
		private var text: TextField;
		
		private var px:int;
		private var py:int;
		private var w:int;
		private var h:int;
		private var sw:int;
		private var sh:int;
		
		[Embed(source = 'net/flashpunk/graphics/04B_03__.TTF', fontFamily = 'default')]
		private static const FONT:Class;
		
		public function Preloader ()
		{
			sw = stage.stageWidth;
			sh = stage.stageHeight;
			
			w = stage.stageWidth * 0.8;
			h = 20;
			
			px = (sw - w) * 0.5;
			py = h*-0.5;
			
			graphics.beginFill(BG_COLOR);
			graphics.drawRect(0, 0, sw, sh);
			graphics.endFill();
			
			progressBar = new Shape();
			
			progressBar.y = sh * 0.5;
			
			addChild(progressBar);
			
			text = new TextField();
			
			text.textColor = FG_COLOR;
			text.selectable = false;
			text.mouseEnabled = false;
			text.defaultTextFormat = new TextFormat("default", 16);
			text.embedFonts = true;
			text.autoSize = "left";
			text.text = "0%";
			text.x = (sw - text.width) * 0.5;
			text.y = sh * 0.5 + h;
			
			addChild(text);
			
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			stage.quality = StageQuality.HIGH;
			stage.displayState = StageDisplayState.NORMAL;
			
			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			
			Sponsor.container = this;
			Sponsor.init(stage);
		}

		public function onEnterFrame (e:Event): void
		{
			if (hasLoaded())
			{
				graphics.clear();
				graphics.beginFill(BG_COLOR);
				graphics.drawRect(0, 0, sw, sh);
				graphics.endFill();
				
				progressBar.graphics.clear();
				
				if (! mustClick) {
					startup();
				} else {
					if (! play) {
						text.scaleX = 2.0;
						text.scaleY = 2.0;
						
						text.textColor = 0xEEEEEE;
				
						text.text = "Play";
						
						var text2:TextField = new TextField();
						
						text2.textColor = FG_COLOR;
						text2.selectable = false;
						text2.mouseEnabled = false;
						text2.defaultTextFormat = new TextFormat("default", 16);
						text2.embedFonts = true;
						text2.autoSize = "left";
						text2.text = "Play";
						text2.x = (sw - text2.width) * 0.5;
						text2.y = text.y;
						text2.scaleX = 2.0;
						text2.scaleY = 2.0;
			
						removeChild(text);
						
						
						play = new SimpleButton(text, text2, text2, text);
						
						play.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
						
						play.y = -16;
						
						addChild(play);
					}
			
					//text.y = (sh - text.height) * 0.5;
				}
			} else {
				var p:Number = (loaderInfo.bytesLoaded / loaderInfo.bytesTotal);
				
				progressBar.graphics.clear();
				
				progressBar.graphics.beginFill(FG_COLOR);
				progressBar.graphics.drawRect(px - 2, py - 2, w + 4, h + 4);
				progressBar.graphics.endFill();
			
				progressBar.graphics.beginFill(BG_COLOR);
				progressBar.graphics.drawRect(px, py, p * w, h);
				progressBar.graphics.endFill();
				
				text.text = int(p * 100) + "%";
			}
			
			text.x = (sw - text.width) * 0.5;
			if (text2) text2.x = (sw - text2.width) * 0.5;
		}
		
		private function onMouseDown(e:MouseEvent):void {
			if (hasLoaded())
			{
				startup();
			}
		}
		
		private function hasLoaded (): Boolean {
			return (loaderInfo.bytesLoaded >= loaderInfo.bytesTotal);
		}
		
		private function startup (): void {
			if (ad) removeChild(ad);
			Preloader.stage = this.stage;
			stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			var mainClass:Class = getDefinitionByName(mainClassName) as Class;
			parent.addChild(new mainClass as DisplayObject);
			
			parent.removeChild(this);
		}
		
		public static function makeURLFunction (url:String): Function
		{
			return function (param:* = null):void {
				var request:URLRequest = new URLRequest(url);
				navigateToURL(request, "_blank");
			}
		}
	}
}


