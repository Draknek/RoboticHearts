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
		public var cog:Spritemap;
		
		public var normalLevels:Array = [];
		public var perfectionLevels:Array = [];
		
		public var heartChoices:Array = [];
		public var cogChoices:Array = [];
		
		public var title:Text;
		
		public var backButton:Button;
		public var backButton2:Button;
		public var muteButton:Button;
		public var muteOverlay:Button;
		
		private var tween:Tween;
		
		public function Menu ()
		{
			title = new Text("These Robotic\nHearts of Mine", 0, 0, {align: "center", scrollX:0, scrollY:0, font:"romance", size: 16, color: Main.PINK});
			addGraphic(title);
			title.x = (FP.width - title.width)*0.5;
			
			heart = new Spritemap(Heart.HEART, 8, 8);
			heart.color = Main.PINK;
			heart.scrollX = 0;
			heart.scrollY = 0;
			
			heart.centerOO();
			
			var titleXSpacing:int = (title.x)*0.5;
			var titleY:int = (title.height)*0.5;
			
			//addGraphic(heart, 0, titleXSpacing + 1, titleY);
			//addGraphic(heart, 0, FP.width - titleXSpacing - 2, titleY);
			
			cog = new Spritemap(Cog.COG, 16, 16);
			cog.frame = Cog.cogChoice;
			cog.scrollX = 0;
			cog.scrollY = 0;
			cog.centerOO();
			cog.alpha = 0.5;
			
			//addGraphic(cog, 10, titleXSpacing, title.height*0.5);
			//addGraphic(cog, 10, FP.width - titleXSpacing, title.height*0.5);
			addGraphic(cog, 10, FP.width*0.5, title.height*0.5 + 3);
			
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
			
			perfectionLevels.push(new Entity(FP.width, 0, new Text("Perfection levels:", 1, 36, {width: FP.width, align: "center"})));
			
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
				tween = FP.tween(FP.camera, {x: FP.width}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
				switchScreen();
			});
			
			var bonusButton:Button = new Button(0, 0, new Text("Bonus levels"), function ():void {
				addList(perfectionLevels);
				if (tween) tween.cancel();
				tween = FP.tween(FP.camera, {x: FP.width}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
				switchScreen();
			});
			
			var graphicsButton:Button = new Button(0, 0, new Text("Change graphics"), function ():void {
				if (tween) tween.cancel();
				tween = FP.tween(FP.camera, {y: FP.height}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
				switchScreen();
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
			
			addElements([playButton, levelsButton, resetData]);
			
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
			
			muteButton.normalLayer = -5;
			muteButton.hoverLayer = -5;
			muteOverlay.normalLayer = -6;
			muteOverlay.hoverLayer = -6;
			
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
			
			addGraphic(new Text("Heart image:", 1, 38 + FP.height - 8, {width: FP.width, align: "center"}));
			addGraphic(new Text("Cog image:", 1, 62 + FP.height - 10, {width: FP.width, align: "center"}));
			
			add(backButton2 = new Button(0, FP.height*2 - 14, new Text("Back to menu"), back));
			backButton2.x = (FP.width - backButton2.width) * 0.5;
		}
		
		private function addElements(list:Array):void
		{
			var h:int = 0;
			
			for each (var o:* in list) {
				if (! o) continue;
				h += o.height;
			}
			
			var start:int = title.y + title.height;
			
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
			var b:Button = new Button(0, 0, new Text((i+1)+"", 0, 0, {width: 17, align:"center"}), function ():void {
				FP.world = new Level(i, mode);
			});
			
			var xSpacing:int = 0 + b.width;
			var ySpacing:int = 0 + b.height;
			
			var levelsPerRow:int = 6;
			var startY:int = title.y + title.height + 8;
			
			if (mode == "perfection") {
				levelsPerRow = 5;
				startY = 48;
			}
			
			var startX:int = FP.width*1.5 - xSpacing*levelsPerRow*0.5;
			
			b.x = startX +    (i % levelsPerRow) * xSpacing;
			b.y = startY + int(i / levelsPerRow) * ySpacing;
			
			var md5:String = MD5.hashBytes(Level.levelPacks[mode].levels[i]);
			
			if (Main.so.data.levels[md5] && Main.so.data.levels[md5].completed) {
				if (Main.so.data.levels[md5].leastClicks
					&& Main.so.data.levels[md5].leastClicks <= Level.levelPacks[mode].minClicksArray[i])
				{
					b.normalColor = 0xFFFF00;
					b.hoverColor = Main.BLACK;
					
					var bitmap:BitmapData = new BitmapData(b.width - 2, b.height - 3, true, 0xFF000000 | Main.PINK);
					bitmap.setPixel32(0, 0, 0x0);
					bitmap.setPixel32(bitmap.width-1, 0, 0x0);
					bitmap.setPixel32(bitmap.width-1, bitmap.height-1, 0x0);
					bitmap.setPixel32(0, bitmap.height-1, 0x0);
					b.graphic = new Graphiclist(new Stamp(bitmap, 0, 1), b.graphic);
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
			var y:int = FP.height+42;
			
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
			var y:int = FP.height+48+16;
			
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
			
			switchScreen(-1);
		}
		
		private function switchScreen (dir:int = 1):void
		{
			Audio.play("rotate");
			FP.tween(cog, {angle: cog.angle-dir*180}, 32, {complete: function ():void {cog.angle = 0;}});
		}
	}
}
