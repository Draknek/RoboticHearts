package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Button extends Entity
	{
		[Embed(source="r.png")]
		public static const RESET: Class;
		[Embed(source="undo.png")]
		public static const UNDO: Class;
		[Embed(source="redo.png")]
		public static const REDO: Class;
		[Embed(source="audio.png")]
		public static const AUDIO: Class;
		[Embed(source="audio-mute.png")]
		public static const AUDIO_MUTE: Class;
		[Embed(source="menu.png")]
		public static const MENU: Class;
		[Embed(source="skip.png")]
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
		
		public function Button (_x:int, _y:int, _gfx:*, _callback:Function, __helpText:String = null, __disabled:Boolean = false)
		{
			x = _x;
			y = _y;
			
			layer = normalLayer;
			
			if (_gfx is Image) {
				image = _gfx as Image;
			} else {
				image = new Image(_gfx);
			}
			
			graphic = image;
			
			setHitbox(image.width, image.height);
			
			type = "button";
			
			callback = _callback;
			
			disabled = __disabled;
			
			helpText = __helpText;
		}
		
		public override function update (): void
		{
			if (!world) return;
			
			var _x:Number = x;
			var _y:Number = y;
			
			if (noCamera) {
				_x += FP.camera.x;
				_y += FP.camera.y;
			}
			
			var over:Boolean = collidePoint(_x, _y, world.mouseX, world.mouseY);
			
			if (over && ! disabled) {
				Input.mouseCursor = "button";
				layer = hoverLayer;
			} else {
				layer = normalLayer;
			}
			
			if (over && _helpText) {
				hoverTimer++;
				
				if (hoverTimer <= 60) {
					_helpText.x = Input.mouseX;
					_helpText.y = Input.mouseY + 2;
				}
			} else {
				hoverTimer = 0;
			}
			
			if (disabled) {
				image.color = disabledColor;
				return;
			}
			
			image.color = (over) ? hoverColor : normalColor;
			
			if (over && Input.mousePressed && callback != null) {
				callback();
			}
		}
		
		public override function render (): void
		{
			graphic.scrollX = noCamera ? 0 : 1;
			graphic.scrollY = noCamera ? 0 : 1;
			
			super.render();
			
			if (_helpText && hoverTimer > 60) {
				FP.rect.x = _helpText.x + 1;
				FP.rect.y = _helpText.y + 2;
				
				FP.rect.width = _helpText.textWidth - 3;
				FP.rect.height = _helpText.textHeight - 5;
				
				if (FP.width <= FP.rect.x + FP.rect.width) {
					_helpText.x -= 2 + FP.rect.width;
					
					if (_helpText.x < 0) _helpText.x = (FP.width - FP.rect.width)*0.5;
					
					FP.rect.x = _helpText.x + 1;
				}
				
				if (FP.height <= FP.rect.y + FP.rect.height) {
					_helpText.y -= 4 + FP.rect.height;
					
					FP.rect.y = _helpText.y + 2;
				}
				
				FP.buffer.fillRect(FP.rect, Main.GREY);
				
				_helpText.render(FP.buffer, FP.zero, FP.zero);
			}
			
		}
		
		public function get disabled ():Boolean {
			return _disabled;
		}
		
		public function set disabled (b:Boolean):void {
			_disabled = b;
			
			if (_disabled) image.color = disabledColor;
			
			type = b ? null : "button";
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

