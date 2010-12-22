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
		
		public var image:Image;
		
		private var _disabled:Boolean = false;
		
		public var callback:Function;
		
		public var normalColor:uint = Main.WHITE;
		public var hoverColor:uint = Main.PINK;
		public var disabledColor:uint = Main.GREY;
		
		public function Button (_x:int, _y:int, _gfx:*, _callback:Function, __disabled:Boolean = false)
		{
			x = _x;
			y = _y;
			
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
		}
		
		public override function update (): void
		{
			if (!world) return;
			
			if (disabled) {
				image.color = disabledColor;
				return;
			}
			
			var over:Boolean = collidePoint(x, y, world.mouseX, world.mouseY);
			image.color = (over) ? hoverColor : normalColor;
			
			if (over && Input.mousePressed && callback != null) {
				callback();
			}
		}
		
		public function get disabled ():Boolean {
			return _disabled;
		}
		
		public function set disabled (b:Boolean):void {
			_disabled = b;
			
			type = b ? null : "button";
		}
	}
}

