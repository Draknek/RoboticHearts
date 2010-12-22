package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.utils.*;
	import flash.ui.Mouse;
	
	public class Menu extends World
	{
			public function Menu ()
			{
				addGraphic(new Text("These Robotic\nHearts of Mine", 0, 8, {align: "center", size:8, width:96}));
				
				var playButton:Button = new Button(0, 0, new Text("Play"), function ():void {
					FP.world = new Level(0);
				});
				
				playButton.x = 48 - playButton.width*0.5;
				playButton.y = 48;
				
				add(playButton);
			}
			
			public override function update ():void
			{
				if (collidePoint("button", mouseX, mouseY)) {
					Mouse.cursor = "button";
				} else {
					Mouse.cursor = "auto";
				}
				
				super.update();
			}
	}
}
