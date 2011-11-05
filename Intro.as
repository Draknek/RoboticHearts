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
		private var outro:Boolean;
		
		public function Intro (_outro:Boolean = false)
		{
			outro = _outro;
			
			var lines:Array = [
				"I've heard it said\nbefore today",
				"That hearts of stone\nare cold",
				"But having known\nthem both I say",
				"That metal bites the\ncolder"
			];
			
			if (outro) {
				lines = [
					"What were we thinking",
					"From our thrones\nup above",
					"To teach creatures\nof metal",
					"To know loss\nbut not love?"
				];
			}
			
			var y:int = 1;
			
			var t:Text;
			
			for (var i:int = 0; i < 4; i++) {
				addGraphic(t = new Text(lines[i].replace("\n", " "), 1, y, {wordWrap: true, leading: 0, width: FP.width - 1, indent: -16, leftMargin: 16}));
				
				y += t.textHeight + 4;
			}
			
			t = new Text("- Anonymous", 0, 0, {align: "right"});
			
			if (outro) {
				t.text = "- Anonymous epitaph";
			}
			
			t.x = FP.width - t.width;
			t.y = FP.height - t.height;
			
			addGraphic(t);
			
			overlay = Image.createRect(FP.width, FP.height, Main.BLACK);
			overlay.alpha = 0;
			
			addGraphic(overlay);
			
			overlay.alpha = 1;
			leaving = true;
			FP.tween(overlay, {alpha: 0}, outro ? 150 : 30, {ease: Ease.cubeIn, tweener:this, complete: function ():void {
				leaving = false;
			}});
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
			
			if (Main.expoMode && ! outro) {
				FP.world = new Level(0, "normal");
			} else {
				FP.world = new Menu;
			}
		}
	}
}
