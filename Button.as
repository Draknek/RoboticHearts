package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Button extends Entity
	{
		[Embed(source="images/r.png")]
		public static const RESET: Class;
		[Embed(source="images/undo.png")]
		public static const UNDO: Class;
		[Embed(source="images/redo.png")]
		public static const REDO: Class;
		[Embed(source="images/audio.png")]
		public static const AUDIO: Class;
		[Embed(source="images/audio-mute.png")]
		public static const AUDIO_MUTE: Class;
		[Embed(source="images/menu.png")]
		public static const MENU: Class;
		[Embed(source="images/skip.png")]
		public static const SKIP: Class;
		
		public var image:Image;
		
		private var _disabled:Boolean = false;
		private var _helpText:Text;
		private var hoverTimer:int = 0;
		
		public var noCamera:Boolean = false;
		public var callback:Function;
		
		public var normalColor:uint = Main.WHITE;
		public var hoverColor:uint = Main.PINK;
		public var disabledColor:uint = Main.GREY;
		
		public var normalLayer:int = -5;
		public var hoverLayer:int = -6;
		
		public function Button (_x:int, _y:int, _gfx:*, _callback:Function, __helpText:String = null, __disabled:Boolean = false, _noCamera:Boolean = false, padding:int = 0)
		{
			x = _x;
			y = _y;
			
			layer = normalLayer;
			
			if (_gfx is Image) {
				image = _gfx as Image;
			} else if (_gfx is String) {
				image = new Text(_gfx);
			} else {
				image = new Image(_gfx);
			}
			
			graphic = image;
			
			image.x = padding;
			
			setHitbox(image.width + padding*2, image.height);
			
			type = "button";
			
			callback = _callback;
			
			disabled = __disabled;
			
			helpText = __helpText;
			
			noCamera = _noCamera;
		}
		
		public override function update (): void
		{
			if (!world || !visible) return;
			
			var _x:Number = x;
			var _y:Number = y;
			
			if (noCamera) {
				_x += FP.camera.x;
				_y += FP.camera.y;
			}
			
			var over:Boolean = Main.inputHover && collidePoint(_x, _y, world.mouseX, world.mouseY);
			
			if (over && ! disabled) {
				Input.mouseCursor = "button";
				layer = hoverLayer;
			} else {
				layer = normalLayer;
			}
			
			if (over && _helpText) {
				hoverTimer++;
				
				var timeBeforeShown:int = Main.touchscreen ? 2 : 20;
				
				if (hoverTimer <= timeBeforeShown) {
					_helpText.x = Input.mouseX;
					_helpText.y = Input.mouseY + 2;
					
					if (Main.touchscreen) {
						_helpText.x = _x - FP.camera.x + width - 2;
						_helpText.y = _y - FP.camera.y + height - 2;
					}
				}
			} else {
				hoverTimer = 0;
			}
			
			if (disabled) {
				image.color = disabledColor;
				return;
			}
			
			image.color = (over) ? hoverColor : normalColor;
			
			if (over && Main.inputClick && callback != null && ! Main.buttonTweak) {
				callback();
			}
		}
		
		public override function render (): void
		{
			graphic.scrollX = noCamera ? 0 : 1;
			graphic.scrollY = noCamera ? 0 : 1;
			
			super.render();
			
			var timeBeforeShown:int = Main.touchscreen ? 2 : 20;
			
			if (_helpText && hoverTimer > timeBeforeShown) {
				FP.rect.x = _helpText.x;
				FP.rect.y = _helpText.y;
				
				FP.rect.width = _helpText.textWidth - 1;
				FP.rect.height = _helpText.textHeight - 1;
				
				if (FP.width <= FP.rect.x + FP.rect.width) {
					_helpText.x -= 2 + FP.rect.width;
					
					if (Main.touchscreen) { _helpText.x -= 4 }
					
					if (_helpText.x < 0) _helpText.x = int((FP.width - FP.rect.width)*0.5);
					
					FP.rect.x = _helpText.x;
				}
				
				if (FP.height <= FP.rect.y + FP.rect.height) {
					_helpText.y -= 4 + FP.rect.height;
					
					if (Main.touchscreen) { _helpText.y -= 4 }
					
					FP.rect.y = _helpText.y + 1;
				}
				
				FP.buffer.fillRect(FP.rect, Main.BLACK);
				
				FP.rect.x += 1;
				FP.rect.y += 1;
				FP.rect.width -= 2;
				FP.rect.height -= 2;
				
				FP.buffer.fillRect(FP.rect, Main.GREY);
				
				_helpText.render(FP.buffer, FP.zero, FP.zero);
			}
			
		}
		
		public function get disabled ():Boolean {
			return _disabled || image.alpha < 0.5;
		}
		
		public function set disabled (b:Boolean):void {
			_disabled = b;
			
			if (_disabled) image.color = disabledColor;
			
			type = b ? null : "button";
		}
		
		public function get alpha ():Number {
			return image.alpha;
		}
		
		public function set alpha (n:Number):void {
			image.alpha = n;
		}
		
		public function get helpText ():String {
			return _helpText ? _helpText.text : "";
		}
		
		public function set helpText (s:String):void {
			if (! s) {
				_helpText = null;
				return;
			}
			
			if (! _helpText) {
				_helpText = new Text(s);
			} else {
				_helpText.text = s;
			}
		}
	}
}

