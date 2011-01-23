package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	import flash.utils.*;
	
	import com.adobe.crypto.*;
	
	public class Menu extends World
	{
		public var time:int = 0;
		public var heart:Spritemap;
		
		public var normalLevels:Array = [];
		public var perfectionLevels:Array = [];
		
		public var heartChoices:Array = [];
		
		public var backButton:Button;
		public var muteButton:Button;
		public var muteOverlay:Button;
		
		private var tween:Tween;
		
		public function Menu ()
		{
			addGraphic(new Text("This Mechanical\nHeart of Mine", 1, 8, {align: "center", size:8, width:96, scrollX:0}));
			
			heart = new Spritemap(Heart.HEART, 8, 8);
			heart.color = Main.PINK;
			heart.scrollX = 0;
			
			addGraphic(heart, 0, 6, 12);
			addGraphic(heart, 0, 81, 12);
			
			var resumeLevel:int = -1;
			var resumeMode:String;
			
			for (var i:int = 0; i < Level.levelPacks["normal"].levels.length; i++) {
				var b:Button = addLevelButton(i);
				
				normalLevels.push(b);
				
				if (resumeLevel < 0 && b.normalColor == Main.WHITE) {
					resumeLevel = i;
					resumeMode = "normal";
				}
			}
			
			for (i = 0; i < Level.levelPacks["perfection"].levels.length; i++) {
				b = addLevelButton(i, "perfection");
				
				perfectionLevels.push(b);
				
				if (resumeLevel < 0 && b.normalColor == Main.WHITE) {
					resumeLevel = i;
					resumeMode = "perfection";
				}
			}
			
			perfectionLevels.push(new Entity(96, 0, new Text("Perfection levels:", 1, 36, {width: 96, align: "center"})));
			
			var playText:String = (resumeLevel == 0) ? "Play" : "Resume";
			
			if (resumeLevel < 0) {
				playText = "Play again";
				resumeLevel = 0;
				resumeMode = "normal";
			}
			
			var playButton:Button = new Button(0, 0, new Text(playText), function ():void {
				FP.world = new Level(resumeLevel, resumeMode);
			});
			
			playButton.x = 48 - playButton.width*0.5;
			playButton.y = 36;
			
			add(playButton);
			
			var levelsButton:Button = new Button(0, 0, new Text("Level select"), function ():void {
				addList(normalLevels);
				tween = FP.tween(FP.camera, {x: 96}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
			});
			
			levelsButton.x = 48 - levelsButton.width*0.5;
			levelsButton.y = 52;
			
			add(levelsButton);
			
			var bonusButton:Button = new Button(0, 0, new Text("Bonus levels"), function ():void {
				addList(perfectionLevels);
				tween = FP.tween(FP.camera, {x: 96}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
			});
			
			bonusButton.x = 48 - bonusButton.width*0.5;
			bonusButton.y = 68;
			
			add(bonusButton);
			
			var oldScreen:Image = new Image(FP.buffer.clone());
			
			addGraphic(oldScreen, -10);
			
			FP.tween(oldScreen, {alpha: 0}, 30, {ease:Ease.sineOut, tweener:this});
			
			add(muteButton = new Button(0, 0, Button.AUDIO, Audio.toggleMute, "Mute"));
			add(muteOverlay = new Button(0, 0, Button.AUDIO_MUTE, null, "Unmute"));
			
			add(backButton = new Button(0, 0, Button.MENU, back, "Back"));
			
			backButton.disabled = true;
			backButton.visible = false;
			
			backButton.noCamera = muteButton.noCamera = muteOverlay.noCamera = true;
			
			muteButton.x = backButton.x + backButton.width;
			muteOverlay.x = muteButton.x;
			
			muteOverlay.normalColor = Main.PINK;
			muteOverlay.hoverColor = Main.WHITE;
			muteOverlay.visible = Audio.mute;
			
			Audio.muteOverlay = muteOverlay;
			
			if (heart.frameCount > 8) {
				var choices:int = heart.frameCount / 8;
				
				for (i = 0; i < choices; i++) {
					heartChoices.push(addHeartChoiceButton(i, (FP.width - choices*8)*0.5 + i*8));
				}
			}
		}
		
		private function addLevelButton (i:int, mode:String = "normal"):Button
		{
			var b:Button = new Button(0, 0, new Text((i+1)+"", 0, 0, {width: 14, align:"center"}), function ():void {
				FP.world = new Level(i, mode);
			});
			
			if (mode == "perfection") {
				b.x = 96 + 6 + 7 + (i%5)*14;
				b.y = 48 + int(i / 5) * 12;
			} else {
				b.x = 96 + 6 + (i%6)*14;
				b.y = 30 + int(i / 6) * 12;
			}
			
			var md5:String = MD5.hashBytes(Level.levelPacks[mode].levels[i]);
			
			if (Main.so.data.levels[md5] && Main.so.data.levels[md5].completed) {
				if (Main.so.data.levels[md5].leastClicks
					&& Main.so.data.levels[md5].leastClicks <= Level.levelPacks[mode].minClicksArray[i])
				{
					b.normalColor = 0xFFFF00;
					b.hoverColor = Main.BLACK;
					
					var bitmap:BitmapData = new BitmapData(11, 7, true, 0xFF000000 | Main.PINK);
					bitmap.setPixel32(0, 0, 0x0);
					bitmap.setPixel32(10, 0, 0x0);
					bitmap.setPixel32(10, 6, 0x0);
					bitmap.setPixel32(0, 6, 0x0);
					b.graphic = new Graphiclist(new Stamp(bitmap, 1, 2), b.graphic);
				} else {
					b.normalColor = 0x00FF00;
				}
			}
			
			return b;
		}
		
		private function addHeartChoiceButton (i:int, x:int):Button
		{
			var s:Spritemap = new Spritemap(Heart.HEART, 8, 8);
			
			s.frame = i*8;
			
			var b:Button = new Button(x, FP.height - 8, s, function ():void {
				Heart.heartChoice = i;
			});
			
			b.helpText = "Change heart image";
			
			add(b);
			
			return b;
		}
		
		public override function update ():void
		{
			Input.mouseCursor = "auto";
			
			var step:int = 50;
			var beatTime:int = 10;
			var modTime:int = time % step;
			
			heart.frame = ((modTime >= 0 && modTime < beatTime) ? 4 : 0);
			
			var i:int = 0;
			for each (var b:Button in heartChoices) {
				b.layer = 0;
				
				if (b.collidePoint(b.x, b.y, mouseX, mouseY)) b.layer = -1;
				
				Spritemap(b.graphic).frame = i*8;
				
				if (i == Heart.heartChoice) Spritemap(b.graphic).frame += heart.frame;
				i++;
			}
			
			heart.frame += Heart.heartChoice*8;
			
			time++;
			
			if (Input.pressed(Key.ESCAPE)) {
				back();
				return;
			}
			
			super.update();
		}
		
		private function back ():void
		{
			if (backButton.disabled) return;
			
			if (tween) tween.cancel();
			
			backButton.disabled = true;
			backButton.visible = false;
			
			tween = FP.tween(FP.camera, {x: 0}, 30, {ease: Ease.sineIn, complete:function():void{
				removeList(normalLevels);
				removeList(perfectionLevels);
			}});
		}
	}
}
