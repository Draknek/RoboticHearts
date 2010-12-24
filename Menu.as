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
		public var time:int = 0;
		public var heart:Spritemap;
		
		public function Menu ()
		{
			addGraphic(new Text("These Robotic\nHearts of Mine", 1, 8, {align: "center", size:8, width:96, scrollX:0}));
			
			heart = new Spritemap(Heart.HEART, 8, 8);
			heart.color = Main.PINK;
			heart.scrollX = 0;
			
			addGraphic(heart, 0, 6, 12);
			addGraphic(heart, 0, 81, 12);
			
			var resumeLevel:int = -1;
			
			for (var i:int = 0; i < Level.levels.length; i++) {
				var b:Button = addLevelButton(i);
				
				if (resumeLevel < 0 && b.normalColor == Main.WHITE) {
					resumeLevel = i;
				}
			}
			
			var playText:String = (resumeLevel == 0) ? "Play" : "Resume";
			
			if (resumeLevel < 0) {
				playText = "Play again";
				resumeLevel = 0;
			}
			
			var playButton:Button = new Button(0, 0, new Text(playText), function ():void {
				FP.world = new Level(resumeLevel);
			});
			
			playButton.x = 48 - playButton.width*0.5;
			playButton.y = 44;
			
			add(playButton);
			
			var levelsButton:Button = new Button(0, 0, new Text("Levels"), function ():void {
				FP.tween(FP.camera, {x: 96}, 30, {ease: Ease.sineIn});
			});
			
			levelsButton.x = 48 - levelsButton.width*0.5;
			levelsButton.y = 60;
			
			add(levelsButton);
		}
		
		private function addLevelButton (i:int):Button
		{
			var b:Button = new Button(0, 0, new Text((i+1)+"", 0, 0, {width: 14, align:"center"}), function ():void {
				FP.world = new Level(i);
			});
			
			var md5:String = MD5.hashBytes(Level.levels[i]);
			
			if (Main.so.data.levels[md5] && Main.so.data.levels[md5].completed) {
				b.normalColor = 0x00FF00;
			}
			
			b.x = 96 + 6 + (i%6)*14;
			b.y = 30 + int(i / 6) * 12;
			
			add(b);
			
			return b;
		}
		
		public override function update ():void
		{
			if (collidePoint("button", mouseX, mouseY)) {
				Mouse.cursor = "button";
			} else {
				Mouse.cursor = "auto";
			}
			
			if (Input.pressed(Key.ESCAPE)) {
				FP.tween(FP.camera, {x: 0}, 30, {ease: Ease.sineIn});
			}
			
			var step:int = 50;
			var beatTime:int = 10;
			var modTime:int = time % step;
			
			heart.frame = (modTime >= 0 && modTime < beatTime) ? 4 : 0;
			
			time++;
			
			super.update();
		}
	}
}
