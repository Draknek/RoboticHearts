
package
{
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.getDefinitionByName;

	import flash.system.*;

	// iPhone: 480x320 => 160x107
	// iPad: 1024x768 => 147x110 (test with 735x550)
	// Browser: 600x480? => 150x120
	// Some Android: 800x480 => 200x120
	// Some Android: 320x240 => 160x120
	[SWF(width = "482", height = "322", backgroundColor="#202020")]
	public class Preloader extends Sprite
	{
		public static const resTest:Boolean = false;
		
		// Change these values
		private static const mustClick: Boolean = resTest;
		private static const mainClassName: String = "Main";
		
		private static const BG_COLOR:uint = 0x202020;
		private static const FG_COLOR:uint = 0xff3366;
		
		public static var stage:Stage;
		
		
		
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
			py = (sh - h) * 0.5;
			
			graphics.beginFill(BG_COLOR);
			graphics.drawRect(0, 0, sw, sh);
			graphics.endFill();
			
			graphics.beginFill(FG_COLOR);
			graphics.drawRect(px - 2, py - 2, w + 4, h + 4);
			graphics.endFill();
			
			progressBar = new Shape();
			
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
			
			if (mustClick) {
				stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			}
			
			stage.quality = StageQuality.HIGH;
			stage.displayState = StageDisplayState.NORMAL;
			
			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
		}

		public function onEnterFrame (e:Event): void
		{
			if (hasLoaded())
			{
				graphics.clear();
				graphics.beginFill(BG_COLOR);
				graphics.drawRect(0, 0, sw, sh);
				graphics.endFill();
				
				if (! mustClick) {
					startup();
				} else {
					text.scaleX = 2.0;
					text.scaleY = 2.0;
				
					text.text = "Click to start";
			
					text.y = (sh - text.height) * 0.5;
				}
			} else {
				var p:Number = (loaderInfo.bytesLoaded / loaderInfo.bytesTotal);
				
				progressBar.graphics.clear();
				progressBar.graphics.beginFill(BG_COLOR);
				progressBar.graphics.drawRect(px, py, p * w, h);
				progressBar.graphics.endFill();
				
				text.text = int(p * 100) + "%";
			}
			
			text.x = (sw - text.width) * 0.5;
		}
		
		private function onMouseDown(e:MouseEvent):void {
			if (hasLoaded())
			{
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				startup();
			}
		}
		
		private function hasLoaded (): Boolean {
			return (loaderInfo.bytesLoaded >= loaderInfo.bytesTotal);
		}
		
		private function startup (): void {
			Preloader.stage = this.stage;
			stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			var mainClass:Class = getDefinitionByName(mainClassName) as Class;
			parent.addChild(new mainClass as DisplayObject);
			
			parent.removeChild(this);
		}
	}
}


