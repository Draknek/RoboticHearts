package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	import flash.system.*;
	
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
		
		public var tank:Sprite;
		
		[Embed(source="images/newgrounds.png")]
		public static const TANK_LOGO: Class;
		
		[Embed(source="images/newgrounds-hover.png")]
		public static const TANK_LOGO_HOVER: Class;
		
		public function Menu ()
		{
			Audio.startMusic();
			
			title = new Text("These Robotic\nHearts of Mine", 0, 0, {align: "center", scrollX:0, scrollY:0, font:"romance", size: 16, color: Main.PINK});
			addGraphic(title, -12);
			title.x = (FP.width - title.width)*0.5;
			
			addFader(-10);
			
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
			addGraphic(cog, -11, FP.width*0.5, title.height*0.5 + 3);
			
			var resumeLevel:int = -1;
			var resumeMode:String;
			
			for (var i:int = 0; i < Level.levelPacks["normal"].levels.length; i++) {
				var b:Button = addLevelButton(i);
				
				if (! b) continue;
				
				normalLevels.push(b);
				
				if (Main.so.data.lastPlayed == Level.levelPacks["normal"].md5[i]) {
					resumeLevel = i;
					resumeMode = "normal";
				}
				
				/*if (resumeLevel < 0 && b.normalColor == Main.WHITE) {
					resumeLevel = i;
					resumeMode = "normal";
				}*/
			}
			
			for (i = 0; i < Level.levelPacks["perfection"].levels.length; i++) {
				b = addLevelButton(i, "perfection");
				
				perfectionLevels.push(b);
				
				/*if (resumeLevel < 0 && b.normalColor == Main.WHITE) {
					resumeLevel = i;
					resumeMode = "perfection";
				}*/
			}
			
			perfectionLevels.push(new Entity(FP.width, 0, new Text("Perfection levels:", 1, 36, {width: FP.width, align: "center"})));
			
			var playText:String = (resumeLevel < 0) ? "Play" : "Resume";
			
			if (resumeLevel < 0) {
				if (Main.so.data.lastPlayed == "gameover") {
					playText = "Play again";
				}
				
				resumeLevel = 0;
				resumeMode = "normal";
			}
			
			add(backButton2 = new Button(0, 0, new Text("Back to menu"), back));
			backButton2.x = (FP.width - backButton2.width) * 0.5;
			backButton2.y = FP.height*2 - 14;
			
			var playButton:Button = new Button(0, 0, new Text(playText), function ():void {
				FP.world = new Level(resumeLevel, resumeMode);
			});
			
			var levelsButton:Button = new Button(0, 0, new Text("Level Select"), function ():void {
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
			
			var highScoresButton:Button = new Button(0, 0, new Text("High Scores"), function ():void {
				backButton2.x = -FP.width + (FP.width - backButton2.width) * 0.5;
				backButton2.y = FP.height - 14;
				
				if (tween) tween.cancel();
				tween = FP.tween(FP.camera, {x: -FP.width}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
				switchScreen();
			});
			
			highScoresButton = new Button(0, 0, new Text("High Scores"), Scores.showScores);
			
			var graphicsButton:Button = new Button(0, 0, new Text("Change graphics"), function ():void {
				if (tween) tween.cancel();
				tween = FP.tween(FP.camera, {y: FP.height}, 30, {ease: Ease.sineIn});
				backButton.disabled = false;
				backButton.visible = true;
				switchScreen();
			});
			
			var creditsText:String = Main.touchscreen ? "Credits" : "Credits";
			
			var creditsButton:Button = new Button(0, 0, new Text(creditsText), function ():void {
				backButton2.x = (FP.width - backButton2.width) * 0.5;
				backButton2.y = FP.height*2 - 14;
				
				if (tween) tween.cancel();
				tween = FP.tween(FP.camera, {y: FP.height}, 30, {ease: Ease.sineIn, complete: function ():void {
					creditMode = true;
				}});
				backButton.disabled = false;
				backButton.visible = true;
				switchScreen();
			});
			
			var resetText:String = Main.expoMode ? "New player" : "Delete saved data";
			
			var resetData:Button = new Button(0, 0, resetText, function ():void {
				Main.resetPlayerData();
				Input.mouseCursor = "auto";
				FP.world = new Intro;
			});
			
			if (Logger.isLocal) {
				var tmp:* = resetData;
				resetData = null;
				for each (var l:* in Main.so.data.levels) {
					resetData = tmp;
					break;
				}
				
				if (Main.so.data.lastPlayed) {
					resetData = tmp;
				}
				
				if (Main.expoMode && ! resetData) {
					// No user data
					
					playButton.callback = tmp.callback;
					levelsButton = null;
				}
			}
			
			var moreGames:Button = makeURLButton("More games", "http://www.toystudio.com/xpromo/?game=robotichearts&store=nook");
			
			var getOnMobile:Button = makeURLButton("Get mobile version", "http://www.draknek.org/games/hearts/mobile.php");
			
			var buttons:Array = [];
			
			if (Main.expoMode) {
				buttons.push(resetData);
			}
			
			buttons.push(playButton);
			buttons.push(levelsButton);
			
			if (Scores.hasScoreboard && ! Main.touchscreen) {
				//buttons.push(highScoresButton);
			}
			
			if (Main.touchscreen) {
				buttons.push(moreGames);
			}
			
			buttons.push(creditsButton);
			
			if (! Main.touchscreen && ! Main.expoMode) {
				buttons.push(moreGames);
			}
			
			if (false && Logger.isLocal && ! Main.expoMode) {
				buttons.push(resetData);
			}
			
			if (! Main.expoMode && ! Main.touchscreen) {
				buttons.push(getOnMobile);
			}
			
			if (Main.isAndroid) {
				buttons.push(new Button(0, 0, "Quit", function ():void {
					try {
						var NativeApplication:Class = getDefinitionByName("flash.desktop.NativeApplication") as Class;
						NativeApplication.nativeApplication.exit();
					} catch (e:Error) {}
				}));
			}
			
			addElements(buttons);
			
			var yourScore:Text = new Text("Your score: #", 0, 0, {color: Main.GREY, leading: 2});
			var submit:Button = new Button(0, 0, new Text("Submit [todo]"), function():void{});
			var highscores:Button = new Button(0, 0, new Text("High scores [todo]"), function():void{});
			var graphs:Button = new Button(0, 0, new Text("Graphs"), function():void{
				var params:Object = {
					highlight: Main.so.data.totalScore/25,
					height: 25,
					scale: 25,
					markers: 500,
					extraWidth: 5
				};
				
				var graph:BitmapData = Graph.makeGraph(Logger.scoreStats, params);
				
				var g:Stamp = new Stamp(graph);
				
				g.x = FP.width*0.5 - g.width*0.5;
				g.y = FP.height*0.5;
				
				addGraphic(g);
				
				FP.tween(g, {x: g.x - FP.width}, 30, {ease: Ease.sineIn});
				FP.tween(submit, {x: submit.x - FP.width}, 30, {ease: Ease.sineIn});
				FP.tween(highscores, {x: highscores.x - FP.width}, 30, {ease: Ease.sineIn});
				FP.tween(graphs, {x: graphs.x - FP.width}, 30, {ease: Ease.sineIn});
				graphs.callback = null;
				switchScreen();
			});
			
			addElements([yourScore, submit, highscores, graphs], -FP.width, 0, 14);
			
			yourScore.text = "Your score:";
			
			var yourPosition:Text = new Text("Position:", yourScore.x + 16, yourScore.y + 10, {color: Main.GREY});
			var yourActualScore:Text = new Text(Main.so.data.totalScore, yourScore.x + yourScore.textWidth + 2, yourScore.y, {});
			var yourActualPosition:Text = new Text("#1", yourScore.x + yourScore.textWidth + 2, yourPosition.y, {});
			//addGraphic(yourPosition);
			addGraphic(yourActualScore);
			//addGraphic(yourActualPosition);
			
			var oldScreen:Image = new Image(FP.buffer.clone());
			
			addGraphic(oldScreen, -20);
			
			FP.tween(oldScreen, {alpha: 0}, 30, {ease:Ease.sineOut, tweener:this});
			
			var buttonPadding:int = Main.touchscreen ? 3 : 1;
			
			if (FP.width < 149 && buttonPadding > 2) buttonPadding = 2;
			if (FP.width > 170) buttonPadding = 4;
			if (FP.width > 180) buttonPadding = 5;
			
			muteButton = new Button(0, 0, Button.AUDIO, Audio.toggleMute, "Mute", false, false, buttonPadding);
			muteOverlay = new Button(0, 0, Button.AUDIO_MUTE, null, "Unmute", false, false, buttonPadding);
			
			var showMute:Boolean = ! Main.expoMode && ! Main.touchscreen;
			
			if (showMute) {
				add(muteButton);
				add(muteOverlay);
			}
			
			add(backButton = new Button(0, 0, Button.MENU, back, "Back", false, false, buttonPadding));
			
			backButton.disabled = true;
			backButton.visible = false;
			backButton.normalLayer = -17;
			backButton.hoverLayer = -18;
			
			backButton.noCamera = muteButton.noCamera = muteOverlay.noCamera = true;
			
			muteButton.x = backButton.x + backButton.width;
			muteOverlay.x = muteButton.x;
			
			muteOverlay.normalColor = Main.PINK;
			muteOverlay.hoverColor = Main.WHITE;
			muteOverlay.visible = Audio.mute;
			
			muteButton.normalLayer = -15;
			muteButton.hoverLayer = -15;
			muteOverlay.normalLayer = -16;
			muteOverlay.hoverLayer = -16;
			
			Audio.muteOverlay = muteOverlay;
			
			//addGraphicChoices();
			addCredits();
			
			tank = new Sprite;
			
			var tank1:Bitmap = new TANK_LOGO;
			var tank2:Bitmap = new TANK_LOGO_HOVER;
			
			//tank.scaleX = tank.scaleY = 2;
			
			tank.addChild(tank1);
			tank.addChild(tank2);
			
			tank1.y = -tank1.height;
			tank2.y = -tank2.height;
			
			tank2.visible = false;
			
			tank.x = 3;
			tank.y = FP.stage.stageHeight - 3;
			
			tank.buttonMode = true;
			
			//FP.engine.addChild(tank);
			
			tank.addEventListener(MouseEvent.CLICK, makeURLFunction("http://www.newgrounds.com/"));
			tank.addEventListener(MouseEvent.MOUSE_OVER, function (e:Event):void { tank2.visible = true; tank.scaleX = tank.scaleY = 1; });
			tank.addEventListener(MouseEvent.MOUSE_OUT, function (e:Event):void { tank2.visible = false; tank.scaleX = tank.scaleY = 1; });
			
			tank.alpha = 0;
			
			FP.tween(tank, {alpha: 1}, 30);
		}
		
		public override function end ():void
		{
			if (tank && tank.parent) {
				FP.tween(tank, {alpha: 0}, 30, function ():void {
					FP.engine.removeChild(tank);
				});
			}
		}
		
		private function addElements(list:Array, offsetX:int = 0, offsetY:int = 0, bottom_padding:Number = 0):void
		{
			var h:int = 0;
			
			var itemCount:int = 0;
			
			for each (var o:* in list) {
				if (! o) continue;
				if (o is Number) {
					h += o;
				} else {
					h += o.height;
				}
				
				itemCount += 1;
			}
			
			var start:int = title.y + title.height;
			
			var padding:int = Number(FP.height - start - h - bottom_padding) / (itemCount + 1);
			
			var y:int = start + padding;
			
			for each (o in list) {
				if (! o) continue;
				
				if (o is Number) {
					y += padding + o;
					continue;
				}
				
				o.x = (FP.width - o.width) * 0.5 + offsetX;
				o.y = y + offsetY;
				
				y += padding + o.height;
				
				if (o is Graphic) o = new Entity(0, 0, o);
				
				add(o);
			}
		}
		
		private function addFader(layer:int):void
		{
			var b:BitmapData = new BitmapData(FP.width, title.height, true, 0x0);
			
			FP.rect.x = 0;
			FP.rect.width = FP.width;
			FP.rect.height = 1;
			
			for (var j:int = 0; j < b.height; j++) {
				FP.rect.y = j;
				var t:Number = 0;
				
				if (j > b.height * 0.5) {
					t = (j - b.height * 0.5) / (b.height * 0.5);
				}
				
				var c:uint = FP.colorLerp(0xFF000000 | Main.BLACK, Main.BLACK, t);
				
				b.fillRect(FP.rect, c);
			}
			
			var g:Stamp = new Stamp(b);
			g.scrollX = 0;
			g.scrollY = 0;
			
			addGraphic(g, layer);
		}
		
		private function makeURLButton (text:String, url:String): Button
		{
			var b:Button = new Button(0, 0, text, makeURLFunction(url));
			
			b.disabledColor = Main.WHITE;
			
			if (Main.expoMode) {
				b.disabled = true;
			}
			
			return b;
		}
		
		public static function makeURLFunction (url:String): Function
		{
			return function (param:* = null):void {
				var request:URLRequest = new URLRequest(url);
				navigateToURL(request, "_blank");
			}
		}
		
		private var creditActions:Array;
		private var creditTimer:int;
		private var creditMode:Boolean = false;
		
		private function addCredits ():void
		{
			var items:Array = [
				[
					"Created by",
					["Alan Hazelden", "http://www.draknek.org/?ref=trhom"],
					"Developed with",
					["FlashPunk", "http://flashpunk.net/"],
				],
				[
					"Published for Nook\nby",
					["Toy Studio", "http://www.toystudio.com/"]
				],
				[
					"Music",
					["ERH", "http://www.freesound.org/people/ERH/sounds/35898/"],
					"Sound effects",
					["Benboncan", "http://www.freesound.org/people/Benboncan/sounds/77718/"],
					["Timbre", "http://www.freesound.org/people/Timbre/sounds/86888/"]
				],
				[
					"Narrative discussions",
					["Tanya Pengelly"],
					["Matthew Hart"],
					["Stephen Lavelle"],
					["Terry Cavanagh"]
				],
				[
					"Thanks to",
					["Alistair Aitcheson", "http://www.alistairaitcheson.com/"],
					["The FlashPunk community"],
					["All my testers"]
				]
			];
			
			var actions:Array = [];
			
			for each (var subitems:Array in items) {
				var list:Array = [];
			
				for each (var obj:* in subitems) {
					if (obj is String) {
						list.push(1);
						obj = new Text(obj, 0, 0, {color: Main.GREY, align: "center"});
					} else if (obj is Array) {
						if (obj.length == 1) {
							obj = new Text(obj[0], 0, 0, {color: Main.WHITE});
						} else {
							obj = makeURLButton(obj[0], obj[1]);
						}
					} else {
						continue;
					}
				
					list.push(obj);
				
					actions.push(obj);
					
					obj.alpha = 0;
				}
				
				list.shift();
				
				list.push(1);
				
				actions.push(150);
				actions.push(list);
				
				addElements(list, 0, FP.height, FP.height * 2 - backButton2.y);
			}
			
			for (var i:int = 0; i < 2; i++) {
				obj = actions.shift();
				
				obj.alpha = 1;
				
				actions.push(obj);
			}
			
			creditActions = actions;
			creditTimer = 60;
		}
		
		private function addLevelButton (i:int, mode:String = "normal"):Button
		{
			if (Level.levelPacks[mode].special[i] & 16) return null;
			
			var b:Button = new Button(0, 0, new Text((i+1)+"", 0, 0, {width: 17, align:"center"}), function ():void {
				FP.world = new Level(i, mode);
			});
			
			var xSpacing:int = 0 + b.width;
			var ySpacing:int = 0 + b.height;
			
			var levelsPerRow:int = 6;
			
			do {
				var levelCount:int = Level.levelPacks[mode].levels.length;
				
				if (mode == "normal") {
					levelCount -= 1;
				}
				
				var rows:int = Math.ceil(levelCount / levelsPerRow);
			
				var startY:int = title.y + title.height;
			
				var padding:int = (FP.height - startY - b.height * rows) * 0.5;
			
				startY += padding;
				
				if (padding < 0) {
					levelsPerRow++;
					continue;
				} else {
					break;
				}
			} while (true);
			
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
				b.helpText = "Completed\n" + Main.so.data.levels[md5].leastClicks + "/" + Level.levelPacks[mode].minClicksArray[i] + " " + Main.clicks_string_lower;
			} else {
				b.helpText = "Not completed";
			}
			
			return b;
		}
		
		private function addGraphicChoices ():void
		{
			var i:int;
			
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
			
			/*if (Input.keyString.substr(-6) == "qrcode") {
				Input.keyString = "";
				FP.world = new QRCodeExport;
				return;
			}*/
			
			if (creditMode) {
				creditTimer--;
				
				if (creditTimer <= 0) {
					var action:* = creditActions.shift();
					creditActions.push(action);
					
					if (action is Array) {
						for each (var item:* in action) {
							if (item is Image || item is Button) {
								FP.tween(item, {alpha: 0}, 30);
							}
						}
						
						creditTimer = 60;
					} else if (action is Number) {
						creditTimer = action;
					} else {
						FP.tween(action, {alpha: 1}, 30);
						creditTimer = 60;
					}
				}
			}
			
			var step:int = 50;
			var beatTime:int = 10;
			var modTime:int = time % step;
			
			heart.frame = ((modTime >= 0 && modTime < beatTime) ? 4 : 0);
			
			if (cogChoices.length) {
				if (time % (step*2) == 0) {
					var g:Spritemap = cogChoices[Cog.cogChoice].graphic;
				
					if (g.angle == 0) {
						FP.tween(g, {angle: g.angle-90}, 16, {complete: function ():void {
							g.angle = 0;
						}});
					}
				}
			}
			
			var i:int = 0;
			if (heartChoices.length) {
				for each (var b:Button in heartChoices) {
					Spritemap(b.graphic).frame = i*8;
				
					if (i == Heart.heartChoice) Spritemap(b.graphic).frame += heart.frame;
					i++;
				}
			}
			
			heart.frame += Heart.heartChoice*8;
			
			time++;
			
			if (Input.pressed(Key.ESCAPE)) {
				back();
				return;
			}
			
			super.update();
		}
		
		public function back ():void
		{
			creditMode = false;
			
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
