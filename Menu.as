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
		public var cogChoices:Array = [];
		
		public var backButton:Button;
		public var backButton2:Button;
		public var muteButton:Button;
		public var muteOverlay:Button;
		
		private var tween:Tween;
		
		public function Menu ()
		{
			var title:Text = new Text("These Mechanical\nHearts of Mine", 0, 8, {align: "center", size:8, scrollX:0, scrollY:0});
			addGraphic(title);
			title.x = (FP.width - title.width)*0.5 + 1;
			
			heart = new Spritemap(Heart.HEART, 8, 8);
			heart.color = Main.PINK;
			heart.scrollX = 0;
			heart.scrollY = 0;
			
			var titleXSpacing:int = (title.x - 8)*0.5;
			
			addGraphic(heart, 0, titleXSpacing + 1, 12);
			addGraphic(heart, 0, FP.width - titleXSpacing - 2 - 8, 12);
			
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
			
			var levelsButton:Button = new Button(0, 0, new Text("Level select"), function ():void {
				addList(normalLevels);
				if (tween) tween.cancel();
				tween = FP.tween(FP.camera, {x: 96}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
			});
			
			var bonusButton:Button = new Button(0, 0, new Text("Bonus levels"), function ():void {
				addList(perfectionLevels);
				if (tween) tween.cancel();
				tween = FP.tween(FP.camera, {x: 96}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
			});
			
			var graphicsButton:Button = new Button(0, 0, new Text("Change graphics"), function ():void {
				if (tween) tween.cancel();
				tween = FP.tween(FP.camera, {y: 96}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
			});
			
			var resetData:Button = null;
			
			if (Logger.isLocal) {
				for each (var l:* in Main.so.data.levels) {
					resetData = new Button(0, 0, new Text("Delete saved data"), function ():void {
						Main.so.data.levels = {};
						Main.so.flush();
						Input.mouseCursor = "auto";
						FP.world = new Intro;
					});
					break;
				}
			}
			
			addElements([playButton, levelsButton, bonusButton, graphicsButton, resetData]);
			
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
					heartChoices.push(addHeartChoiceButton(i, choices));
				}
			}
			
			var cogSpritemap:Spritemap = new Spritemap(Cog.COG, 16, 16);
			
			for (i = 0; i < cogSpritemap.frameCount; i++) {
				cogChoices.push(addCogChoiceButton(i, cogSpritemap.frameCount));
			}
			
			addGraphic(new Text("Heart image:", 1, 38 + 96 - 8, {width: 96, align: "center"}));
			addGraphic(new Text("Cog image:", 1, 62 + 96 - 10, {width: 96, align: "center"}));
			
			add(backButton2 = new Button(0, 96*2 - 14, new Text("Back to menu"), back));
			backButton2.x = (FP.width - backButton2.width) * 0.5;
		}
		
		private function addElements(list:Array):void
		{
			var h:int = 0;
			
			for each (var o:* in list) {
				if (! o) continue;
				h += o.height;
			}
			
			var start:int = 24 + 4;
			
			var padding:int = Number(FP.height - start - h) / (list.length + 1);
			
			var y:int = start + padding;
			
			for each (o in list) {
				if (! o) continue;
				o.x = (FP.width - o.width) * 0.5;
				o.y = y;
				add(o);
				y += padding + o.height;
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
				b.y = 30 + int(i / 6) * 12 - 4; // magic constant 4 is because I have too many levels now
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
				b.helpText = "Completed\n" + Main.so.data.levels[md5].leastClicks + "/" + Level.levelPacks[mode].minClicksArray[i] + " clicks";
			} else {
				b.helpText = "Not completed";
			}
			
			return b;
		}
		
		private function addHeartChoiceButton (i:int, l:int):Button
		{
			var s:Spritemap = new Spritemap(Heart.HEART, 8, 8);
			
			s.frame = i*8;
			
			var x:int = (FP.width - l*8) * 0.5 + i*8;
			var y:int = 96+42;
			
			var b:Button = new Button(x, y, s, function ():void {
				Heart.heartChoice = i;
			});
			
			add(b);
			
			return b;
		}
		
		private function addCogChoiceButton (i:int, l:int):Button
		{
			var s:Spritemap = new Spritemap(Cog.COG, 16, 16);
			
			s.x = 8;
			s.y = 8;
			s.originX = 8;
			s.originY = 8;
			
			s.frame = i;
			
			var x:int = (FP.width - l*16) * 0.5 + i*16;
			var y:int = 96+48+16;
			
			var b:Button = new Button(x, y, s, function ():void {
				Cog.cogChoice = i;
				s.angle = 0;
				
				FP.tween(s, {angle: s.angle-90}, 16, {complete: function ():void {
					s.angle = 0;
				}});
			});
			
			b.layer = -2 - l + i;
			
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
			
			if (time % (step*2) == 0) {
				var g:Spritemap = cogChoices[Cog.cogChoice].graphic;
				
				if (g.angle == 0) {
					FP.tween(g, {angle: g.angle-90}, 16, {complete: function ():void {
						g.angle = 0;
					}});
				}
			}
			
			var i:int = 0;
			for each (var b:Button in heartChoices) {
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
			if (backButton.disabled) {
				if (Logger.isLocal) {
					FP.world = new Intro;
				} else {
					return;
				}
			}
			
			if (tween) tween.cancel();
			
			backButton.disabled = true;
			backButton.visible = false;
			
			tween = FP.tween(FP.camera, {x: 0, y: 0}, 30, {ease: Ease.sineIn, complete:function():void{
				removeList(normalLevels);
				removeList(perfectionLevels);
			}});
		}
	}
}
