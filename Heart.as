package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Heart extends Entity
	{
		[Embed(source="heart.png")]
		public static const HEART: Class;
		
		public var sprite:Spritemap;
		public var image:Image;
		
		public var rot:int;
		public var highlight:Boolean = false;
		
		public static var heartChoice:int = 1;
		
		public function Heart (_x:int = 0, _y:int = 0, _rot:int = -1)
		{
			x = _x*8 + 4;
			y = _y*8 + 4;
			
			sprite = new Spritemap(HEART, 8, 8);
			image = sprite;
			if (_rot < 0) _rot = FP.rand(4);
			rot = _rot;
			sprite.frame = rot + heartChoice*8;
			image.centerOO();
			image.color = (rot == 0) ? Main.PINK : Main.WHITE;
			
			graphic = image;
			
			type = "heart";
			
			setHitbox(6, 6, 3, 3);
		}
		
		public override function update (): void
		{
			var level:Level = Level(world);
			var beating:int = level ? level.beating[rot] : 0;
			sprite.frame = rot + beating*4 + heartChoice*8;
		}
		
		public override function render (): void
		{
			if (highlight) {
				var c:uint = image.color;
				image.color = (c == Main.PINK) ? 0xA0A0A0 & image.color : Main.GREY;
			}
			
			super.render();
			
			if (highlight) {
				image.color = c;
			}
		}
	}
}

