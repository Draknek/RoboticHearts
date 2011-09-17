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
		
		public function Intro (outro:Boolean = false)
		{
			var lines:Array = [
				"I've heard it said\n\tbefore today",
				"That hearts of stone\n\tare cold",
				"But having known\n\tthem both I say",
				"That metal bites the\n\tcolder"
			];
			
			if (outro) {
				lines = [
					"What were we thinking",
					"From our thrones\n\tup above",
					"To teach creatures\n\tof metal",
					"To know loss\n\tbut not love?"
				];
			}
			
			var y:int = 1;
			
			for (var i:int = 0; i < 4; i++) {
				addGraphic(new Text(lines[i], 1, y));
				
				y += 20;
				
				if (outro && i == 0) y -= 8;
			}
			
			var t:Text = new Text("- Anonymous", 0, 0, {align: "right"});
			
			if (outro) {
				t.text = "- Anonymous epitaph";
			}
			
			t.x = FP.width - t.width;
			t.y = FP.height - t.height;
			
			addGraphic(t);
			
			overlay = Image.createRect(FP.width, FP.height, Main.BLACK);
			overlay.alpha = 0;
			
			addGraphic(overlay);
			
			if (outro) {
				overlay.alpha = 1;
				leaving = true;
				FP.tween(overlay, {alpha: 0}, 150, {ease: Ease.cubeIn, tweener:this, complete: function ():void {
					leaving = false;
				}});
			}
		}
		
		public override function update ():void
		{
			Input.mouseCursor = "auto";
			
			if (leaving) return;
			
			if (Main.anyInput) {
				leaving = true;
				FP.tween(overlay, {alpha: 1}, 90, {tweener:this, complete: next});
			}
		}
		
		private function next ():void
		{
			overlay.alpha = 1;
			overlay.render(FP.buffer, FP.zero, FP.zero);
			FP.world = new Menu;
		}
	}
}
