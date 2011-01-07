package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Intro extends World
	{
		private var leaving:Boolean = false;
		private var overlay:Image;
		
		public function Intro ()
		{
			var lines:Array = [
				"I've heard it said\n\tbefore today,",
				"That hearts of stone\n\tare cold,",
				"But having known\n\tthem both I say,",
				"That metal bites the\n\tcolder."
			];
			
			var y:int = 1;
			
			for (var i:int = 0; i < 4; i++) {
				addGraphic(new Text(lines[i], 1, y));
				
				y+= 20;
			}
			
			var t:Text = new Text("- Anonymous", 0, 80);
			t.x = 96 - t.width;
			
			addGraphic(t);
			
			overlay = Image.createRect(96, 96, Main.BLACK);
			overlay.alpha = 0;
			
			addGraphic(overlay);
		}
		
		public override function update ():void
		{
			if (leaving) return;
			
			if (Input.mousePressed || Input.pressed(Key.ANY)) {
				leaving = true;
				FP.tween(overlay, {alpha: 1}, 90, {tweener:this, complete: next});
			}
		}
		
		private function next ():void
		{
			overlay.alpha = 1;
			overlay.render(FP.buffer, FP.zero, FP.zero);
			FP.world = new Menu;
			Audio.startMusic();
		}
	}
}
