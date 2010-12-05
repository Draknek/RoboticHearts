package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Player extends Entity
	{
		public var vx: Number = 0;
		public var vy: Number = 0;
		
		public function Player (_x:Number = 0, _y:Number = 0, _vx:Number = 0, _vy:Number = 0)
		{
			x = _x;
			y = _y;
			vx = _vx;
			vy = _vy;
		}
		
		public override function update (): void
		{
			x += vx;
			y += vy;
		}
	}
}

