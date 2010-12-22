package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.utils.*;
	import flash.ui.Mouse;
	
	import com.adobe.crypto.*;
	
	public class Menu extends World
	{
			public function Menu ()
			{
				addGraphic(new Text("These Robotic\nHearts of Mine", 0, 8, {align: "center", size:8, width:96, scrollX:0}));
				
				var playButton:Button = new Button(0, 0, new Text("Play"), function ():void {
					FP.world = new Level(0);
				});
				
				playButton.x = 48 - playButton.width*0.5;
				playButton.y = 44;
				
				add(playButton);
				
				for (var i:int = 0; i < Level.levels.length; i++) {
					addLevelButton(i);
				}
				
				var levelsButton:Button = new Button(0, 0, new Text("Levels"), function ():void {
					FP.tween(FP.camera, {x: 96}, 30, {ease: Ease.sineIn});
				});
				
				levelsButton.x = 48 - levelsButton.width*0.5;
				levelsButton.y = 60;
				
				add(levelsButton);
			}
			
			private function addLevelButton (i:int):void
			{
				var b:Button = new Button(0, 0, new Text((i+1)+"", 0, 0, {width: 12, align:"center"}), function ():void {
					FP.world = new Level(i);
				});
				
				var md5:String = MD5.hashBytes(Level.levels[i]);
				
				if (Main.so.data.levels[md5] && Main.so.data.levels[md5].completed) {
					b.normalColor = 0x00FF00;
				}
				
				b.x = 96 + 24 + (i%4)*12;
				b.y = 36 + int(i / 4) * 12;
				
				add(b);
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
