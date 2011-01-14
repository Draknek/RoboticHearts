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
		
		public var callback:Function;
		
		public var normalColor:uint = Main.WHITE;
		public var hoverColor:uint = Main.PINK;
		public var disabledColor:uint = Main.GREY;
		
		public function Button (_x:int, _y:int, _gfx:*, _callback:Function, __helpText:String = null, __disabled:Boolean = false)
		{
			x = _x;
			y = _y;
			
			layer = -5;
			
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
			
			var over:Boolean = collidePoint(x, y, world.mouseX, world.mouseY);
			
			if (over && _helpText) {
				hoverTimer++;
				
				if (hoverTimer <= 60) {
					_helpText.x = world.mouseX;
					_helpText.y = world.mouseY + 2;
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
			super.render();
			
			if (_helpText && hoverTimer > 60) {
				FP.rect.x = _helpText.x + 1;
				FP.rect.y = _helpText.y + 2;
				
				FP.rect.width = _helpText.textWidth - 3;
				FP.rect.height = _helpText.textHeight - 5;
				
				if (FP.width <= FP.rect.x + FP.rect.width) {
					_helpText.x -= 2 + FP.rect.width;
					
					FP.rect.x = _helpText.x + 1;
				}
				
				if (FP.height <= FP.rect.y + FP.rect.height) {
					_helpText.y -= 4 + FP.rect.height;
					
					FP.rect.y = _helpText.y + 2;
				}
				
				FP.buffer.fillRect(FP.rect, Main.GREY);
				
				_helpText.render(FP.buffer, FP.zero, FP.camera);
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

