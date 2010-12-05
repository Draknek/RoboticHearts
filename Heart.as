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
		
		public function Heart (_x:int = 0, _y:int = 0)
		{
			x = _x*8 + 4;
			y = _y*8 + 4;
			
			sprite = new Spritemap(HEART, 8, 8);
			image = sprite;
			rot = FP.rand(4);
			sprite.frame = rot;
			image.centerOO();
			
			graphic = image;
			
			type = "heart";
			
			setHitbox(6, 6, 3, 3);
		}
		
		public override function update (): void
		{
			sprite.frame = rot;
			image.color = (rot == 0) ? Main.PINK : Main.WHITE;
		}
		
		public override function render (): void
		{
			super.render();
		}
	}
}

