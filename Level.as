package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Level extends World
	{
		public var lookup:Vector.<Entity> = new Vector.<Entity>(W*H);
		
		public static const W:int = 12;
		public static const H:int = 12;
		
		public function Level ()
		{
			var e:Entity;
			var x:int = 5;
			var y:int = 5;
			
			e = new Cog(x, y);
			lookup[index(x,y)] = e;
			lookup[index(x+1,y)] = e;
			lookup[index(x,y+1)] = e;
			lookup[index(x+1,y+1)] = e;
			add(e);
			
			for (x = 0; x < W; x++) {
				for (y = 0; y < H; y++) {
					if (get(x, y)) { continue; }
					
					/*if (x != W-1 && y != H-1 && !get(x+1, y) && !get(x, y+1) && FP.rand(4)==0) {
						e = new Cog(x, y);
						lookup[index(x,y)] = e;
						lookup[index(x+1,y)] = e;
						lookup[index(x,y+1)] = e;
						lookup[index(x+1,y+1)] = e;
					} else*/ {
						e = new Heart(x, y);
						lookup[index(x,y)] = e;
					}
					
					add(e);
				}
			}
		}
		
		/*public override function updateTweens ():void {
			if (Input.pressed(Key.SPACE)) super.updateTweens();
		}*/
		
		public static function index (i:int, j:int):int {
			return j*W + i;
		}
		
		public function get (i:int, j:int):Entity {
			return lookup[index(i, j)];
		}
		
		public override function update (): void
		{
			if (Input.pressed(Key.R)) FP.world = new Level();
			
			super.update();
		}
		
		public override function render (): void
		{
			super.render();
		}
	}
}

