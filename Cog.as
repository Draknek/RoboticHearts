package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Cog extends Entity
	{
		[Embed(source="cog.png")]
		public static const COG: Class;
		
		public var image:Image;
		
		public static var rotating:Cog = null;
		
		public function Cog (_x:int = 0, _y:int = 0)
		{
			x = _x*8 + 8;
			y = _y*8 + 8;
			
			image = new Image(COG);
			image.centerOO();
			
			graphic = image;
			
			setHitbox(16, 16, 8, 8);
		}
		
		public override function added (): void
		{
			rotating = null;
		}
		
		public override function update (): void
		{
			var over:Boolean = collidePoint(x, y, world.mouseX, world.mouseY);
			image.color = (over) ? Main.PINK : Main.WHITE;
			
			if (over && Input.mousePressed) {
				if (rotating) {
					return;
				}
				
				rotating = this;
				
				var a:Array = [];
				var img:Image;
				
				world.collideRectInto("heart", x - 16, y - 16, 32, 32, a);
				
				for each (var h:Heart in a) {
					img = h.image;
					img.originX = x - h.x + 4;
					img.originY = y - h.y + 4;
					img.x = 0;
					img.y = 0;
					
					h.x = x;
					h.y = y;
					
					FP.tween(img, {angle: img.angle-90}, 20, {tweener:this});
				}
				
				function stoppedRotating ():void
				{
					clearTweens();
					
					rotating = null;
					
					for each (h in a) {
						img = h.image;
						img.angle = 0;
						
						h.rot = (h.rot + 1) % 4;
						
						h.x = x + (img.originY - 4);
						h.y = y - (img.originX - 4);
						img.centerOO();
					}
				}
				
				FP.tween(image, {angle: image.angle-90}, 20, {complete:stoppedRotating});
			}
		}
	}
}

