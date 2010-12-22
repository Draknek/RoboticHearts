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
		public var sprite:Spritemap;
		
		public static var rotating:Cog = null;
		
		public function Cog (_x:int = 0, _y:int = 0)
		{
			x = _x*8 + 8;
			y = _y*8 + 8;
			
			sprite = new Spritemap(COG, 32, 32);
			image = sprite;//new Image(COG);
			image.centerOO();
			
			graphic = image;
			
			setHitbox(16, 16, 8, 8);
			
			type = "cog";
		}
		
		public override function added (): void
		{
			rotating = null;
		}
		
		public override function update (): void
		{
			if (!world) return;
			
			if (Level(world).gameOver) {
				image.color = Main.WHITE;
				image.angle -= 45 / 4.0;
				return;	
			}
			
			var over:Boolean = collidePoint(x, y, world.mouseX, world.mouseY);
			image.color = (over) ? Main.PINK : Main.WHITE;
			//sprite.frame = (over) ? 1 : 0;
			
			if (over) {
				var a:Array = [];
			
				world.collideRectInto("heart", x - 16, y - 16, 32, 32, a);
				
				for each (var h:Heart in a) {
					h.highlight = true;
				}
			}
			
			if (over && Input.mousePressed) {
				Level(world).actions.push(this);
				
				Level(world).clicks++;
				
				Logger.click();
			}
		}
		
		public function go (change:int = 1, speed:Number = 1, callback:Function = null):Boolean
		{
			if (rotating) return false;
			
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
				img.color = Main.WHITE;
				
				h.x = x;
				h.y = y;
				
				FP.tween(img, {angle: img.angle-90*change}, 16/speed, {tweener:this});
			}
			
			function stoppedRotating ():void
			{
				clearTweens();
				
				rotating = null;
				
				for each (h in a) {
					img = h.image;
					img.angle = 0;
					
					h.rot = (h.rot + change + 4) % 4;
					
					img.color = (h.rot == 0) ? Main.PINK : Main.WHITE;
					
					if (change == 2 || change == -2) {
						h.x = x + (img.originX - 4);
						h.y = y + (img.originY - 4);
					} else {
						h.x = x + change*(img.originY - 4);
						h.y = y - change*(img.originX - 4);
					}
					
					img.centerOO();
				}
			}
			
			FP.tween(image, {angle: image.angle-90*change}, 16/speed, {complete:stoppedRotating});
			
			return true;
		}
		
		public function undo ():Boolean
		{
			var speed:Number = Level(world).reseting ? 4 : 2;
			return go(-1, speed);
		}
		
		public function redo ():Boolean
		{
			return go(1, 2);
		}
	}
}

