package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	import flash.geom.*;
	import flash.utils.*;
	
	import com.adobe.crypto.*;
	
	public class Level extends LoadableWorld
	{
		public var lookup:Vector.<Entity> = new Vector.<Entity>(W*H);
		
		public static const W:int = 12;
		public static const H:int = 12;
		
		public var data:ByteArray;
		
		public var editing:Boolean = false;
		public var gameOver:Boolean = false;
		public var clickThrough:Boolean = false;
		public var hasEdited:Boolean = false;
		
		public var id:int;
		
		public var beating:Array = [0,0,0,0];
		
		public var time:int = 0;
		public var clicks:int = 0;
		
		public var undoStack:Array = [];
		public var redoStack:Array = [];
		
		public var actions:Array = [];
		
		public var menuButton:Button;
		public var muteButton:Button;
		public var muteOverlay:Button;
		public var resetButton:Button;
		public var undoButton:Button;
		public var redoButton:Button;
		
		public var reseting:Boolean = false;
		
		[Embed(source="levels/main.lvls", mimeType="application/octet-stream")]
		public static const LEVELS:Class;
		
		[Embed(source="levels/perfection.lvls", mimeType="application/octet-stream")]
		public static const PERFECTION_LEVELS:Class;
		
		[Embed(source="levels/main.story.txt", mimeType="application/octet-stream")]
		public static const STORY:Class;
		
		public static var levelPacks:Object = {};
		
		public var storyText:Image;
		public var clickCounter:Text;
		public var minClicks:int;
		
		public var mode:String;
		
		public var mirrorX:Boolean = false;
		public var mirrorY:Boolean = false;
		public var stopSpinHack:Boolean = false;
		public var halfSlowHack:Boolean = false;
		public var endGameHack:Boolean = false;
		
		public var wasUnfocused:Boolean = false;
		public var somethingHighlighted:Boolean = false;
		
		public var black:Image;
		
		public static function loadLevels ():void
		{
			loadLevels2("normal", new LEVELS, new STORY);
			loadLevels2("perfection", new PERFECTION_LEVELS);
		}
		
		private static function loadLevels2(mode:String, data:ByteArray, storyText:String = null):void
		{
			levelPacks[mode] = {};
			
			if (storyText) {
				levelPacks[mode].story = storyText.split("\n");
			}
			
			levelPacks[mode].levels = [];
			levelPacks[mode].md5 = [];
			levelPacks[mode].special = [];
			levelPacks[mode].minClicksArray = [];
			
			data.position = 0;
			
			var levelCount:int = data.readInt();
			
			for (var i:int = 0; i < levelCount; i++) {
				var clickCount:int = data.readInt();
				var flags:int = data.readInt();
				
				levelPacks[mode].minClicksArray.push(clickCount);
				levelPacks[mode].special.push(flags);
				
				var levelSize:int = data.readInt();
				
				var levelData:ByteArray = new ByteArray;
			
				data.readBytes(levelData, 0, levelSize);
				
				levelPacks[mode].levels.push(levelData);
				levelPacks[mode].md5.push(MD5.hashBytes(levelData));
			}
		}
		
		public override function getWorldData (): *
		{
			var b:ByteArray = new ByteArray;
			
			b.writeShort(Main.SAVEFILE_VERSION);
			
			var cogs:Array = [];
			var hearts:Array = [];
			
			var e:Entity;
			
			getType("cog", cogs);
			getType("heart", hearts);
			
			b.writeInt(cogs.length);
			
			for each (e in cogs) {
				b.writeInt(e.x);
				b.writeInt(e.y);
			}
			
			b.writeInt(hearts.length);
			
			for each (e in hearts) {
				b.writeInt(e.x);
				b.writeInt(e.y);
				b.writeInt(Heart(e).rot);
			}
			
			return b;
		}
		
		public override function setWorldData (b: ByteArray): void {
			resetState();
			minClicks = 0;
			hasEdited = true;
			
			b.position = 0;
			
			var version:int = b.readShort();
			
			if (version == 0) {
				b.position = 0;
			}
			
			data = b;
			
			var a:Array = [];
			
			getType("cog", a);
			getType("heart", a);
			
			removeList(a);
			
			var l:int = b.readInt();
			var i:int;
			var x:int;
			var y:int;
			var rot:int;
			
			for (i = 0; i < l; i++) {
				x = b.readInt();
				y = b.readInt();
				
				if (version == 0) {
					x = x*8 + 8;
					y = y*8 + 8;
				}
				
				add(new Cog(x, y));
			}
			
			l = b.readInt();
			
			for (i = 0; i < l; i++) {
				x = b.readInt();
				y = b.readInt();
				rot = b.readInt();
				
				if (version == 0) {
					x = x*8 + 4;
					y = y*8 + 4;
				}
				
				add(new Heart(x, y, rot));
			}
			
			updateLists();
		}
		
		public function Level (_id:int, _mode:String)
		{
			mode = _mode;
			
			id = _id;
			
			Logger.startLevel(id, mode);
			
			add(redoButton = new Button(0, 0, Button.REDO, redo, "Redo", true, true));
			add(undoButton = new Button(0, 0, Button.UNDO, undo, "Undo", true, true));
			add(resetButton = new Button(0, 0, Button.RESET, reset, "Reset", false, true));
			
			muteButton = new Button(0, 0, Button.AUDIO, Audio.toggleMute, "Mute", false, true);
			muteOverlay = new Button(0, 0, Button.AUDIO_MUTE, null, "Unmute", false, true);
			
			if (! Main.expoMode) {
				add(muteButton);
				add(muteOverlay);
			}
			
			add(menuButton = new Button(0, 0, Button.MENU, gotoMenu, "Menu", false, true));
			
			muteButton.x = menuButton.x + menuButton.width;
			
			if (Main.expoMode) {
				muteButton.x = menuButton.x;
			}
			
			resetButton.x = muteButton.x + muteButton.width;
			undoButton.x = resetButton.x + resetButton.width;
			redoButton.x = undoButton.x + undoButton.width;
			muteOverlay.x = muteButton.x;
			
			menuButton.normalLayer = muteButton.normalLayer = -20;
			menuButton.hoverLayer = muteButton.hoverLayer = -21;
			muteOverlay.normalLayer = -21;
			muteOverlay.hoverLayer = -22;
			
			muteOverlay.normalColor = Main.PINK;
			muteOverlay.hoverColor = Main.WHITE;
			muteOverlay.visible = Audio.mute;
			
			Audio.muteOverlay = muteOverlay;
			
			if (levelPacks[mode].levels[id+1]) {
				add(new Button(FP.width-8, FP.height-10, Button.SKIP, skip, "Skip level", false, true));
			}
			
			var modeCode:String = "";
			
			if (mode == "perfection") modeCode = "P";
			
			var levelIDDisplay:Text = new Text("Level " + modeCode+(id+1), 0, -1);
			levelIDDisplay.x = FP.width + 2 - levelIDDisplay.width;
			levelIDDisplay.scrollX = levelIDDisplay.scrollY = 0;
			addGraphic(levelIDDisplay, -15);
			
			clickCounter = new Text("Clicks: 0", -1, FP.height - 10);
			clickCounter.scrollX = clickCounter.scrollY = 0;
			addGraphic(clickCounter);
			
			if (mode == "normal") {
				if (id == 0) {
					addGraphic(new Text("Click cogs to\nbrighten hearts", 0, 64, {align:"center", size:8, width: 96, leading: 3}));
				}
				else if (id == 1) {
					addGraphic(new Text("Make all upright", 0, 74, {align:"center", size:8, width: 96}));
				}
				else if (id == 2) {
					addGraphic(new Text("R to reset", 0, 74, {align:"center", size:8, width: 96}));
				}
				else if (id == 3) {
					addGraphic(new Text("Ctrl+Z to undo", 0, 74, {align:"center", size:8, width: 96}));
				}
				/*else if (id == 4) {
					addGraphic(new Text("Hint: try to keep\nsame-aligned\nhearts together", 0, 58, {align:"center", size:8, width: 96}));
				}*/
			}
			
			if (levelPacks[mode].story && levelPacks[mode].story[id] && levelPacks[mode].story[id].length) {
				var text:String = levelPacks[mode].story[id];
				text = text.split(" / ").join("\n\n");
				
				var storyWidth:int = Math.max(FP.width*0.75, 120);
				
				storyText = new Text(text, 1, 0, {width: storyWidth, align:"center", wordWrap:true, leading: 3});
				
				storyText.x = (FP.width - storyText.width) * 0.5 + 1;
				storyText.y = (FP.height - storyText.height) * 0.5;
				
				var bitmap:BitmapData = new BitmapData(FP.width, FP.height, false, Main.PINK);
				
				storyText.render(bitmap, FP.zero, camera);
				
				storyText = new Image(bitmap);
				
				storyText.scrollX = storyText.scrollY = 0;
				
				addGraphic(storyText, -9);
			}
			
			var oldScreen:Image = new Image(FP.buffer.clone());
			
			oldScreen.scrollX = oldScreen.scrollY = 0;
			
			addGraphic(oldScreen, -10);
			
			FP.tween(oldScreen, {alpha: 0}, 30, {ease:Ease.sineOut, tweener:this});
			
			if (levelPacks[mode].special[id]) {
				var flags:int = levelPacks[mode].special[id];
				
				if (flags & 1) mirrorX = true;
				if (flags & 2) mirrorY = true;
				if (flags & 4) stopSpinHack = true;
				if (flags & 8) halfSlowHack = true;
				if (flags & 16) endGameHack = true;
			}
			
			if (endGameHack) {
				updateLists();
				removeAll();
				addGraphic(storyText, -9);
				addGraphic(oldScreen, -10);
				
				black = Image.createRect(FP.width, FP.height, Main.BLACK);
				black.alpha = 0;
				black.scrollX = 0;
				black.scrollY = 0;
				addGraphic(black, -20);
			}
			
			var _data:ByteArray = levelPacks[mode].levels[id];
			
			if (_data) {
				setWorldData(_data);
				hasEdited = false;
				minClicks = levelPacks[mode].minClicksArray[id];
				return;
			}
			
			updateLists();
			
			removeAll();
			
			var bg:Image = Image.createRect(FP.width, FP.height, Main.PINK);
			bg.scrollX = 0;
			bg.scrollY = 0;
			
			addGraphic(bg);
			
			var t:Text = new Text("And that is the story\n\nOf these robotic hearts of mine\n\n\nThanks for playing!", 0, 0, {width: FP.width, wordWrap: true, align: "center", leading: 3, scrollX:0, scrollY:0});
			
			t.y = (FP.height - t.height)*0.5;
			
			addGraphic(t);
		}
		
		public static function index (i:int, j:int):int {
			return j*W + i;
		}
		
		public function get (i:int, j:int):Entity {
			return lookup[index(i, j)];
		}
		
		public function gotoMenu ():void
		{
			FP.world = new Menu;
		}
		
		public function skip ():void
		{
			FP.world = new Level(id+1, mode);
		}
		
		public function reset ():void
		{
			if (endGameHack) return;
			
			reseting = true;
			
			Logger.restartLevel(id, mode);
		}
		
		public function resetState ():void
		{
			forgetPast();
			forgetFuture();
			actions.length = 0;
			clicks = 0;
		}
		
		public function forgetPast (): void
		{
			undoStack.length = 0;
			undoButton.disabled = true;
		}
		
		public function forgetFuture (): void
		{
			redoStack.length = 0;
			redoButton.disabled = true;
		}
		
		public override function undo (): void
		{
			if (endGameHack) return;
			actions.push(actuallyUndo);
		}
		
		public function actuallyUndo (): void
		{
			if (undoStack.length == 0) { return; }
			
			var cog:Cog = undoStack.pop();
			
			var success:Boolean = cog.undo();
			
			if (!success) {
				undoStack.push(cog);
				return;
			}
			
			clicks--;
			
			redoStack.push(cog);
			
			undoButton.disabled = (undoStack.length == 0);
			redoButton.disabled = (redoStack.length == 0);
		}
		
		public override function redo (): void
		{
			if (endGameHack) return;
			actions.push(actuallyRedo);
		}
		
		public function actuallyRedo (): void
		{
			if (redoStack.length == 0) { return; }
			
			var cog:Cog = redoStack.pop();
			
			var success:Boolean = cog.redo();
			
			if (!success) {
				redoStack.push(cog);
				return;
			}
			
			clicks++;
			
			undoStack.push(cog);
			
			undoButton.disabled = (undoStack.length == 0);
			redoButton.disabled = (redoStack.length == 0);
		}
		
		public override function begin (): void
		{
			super.begin();
			
			if (data) {
				var md5:String = MD5.hashBytes(data);
			
				Main.so.data.lastPlayed = md5;
			} else {
				Main.so.data.lastPlayed = "gameover";
			}
		}
		
		public override function update (): void
		{
			var a:Array;
			
			camera.x = -(FP.width - 96)*0.5;
			camera.y = -(FP.height - 96)*0.5;
			
			if (data) {
				var md5:String = MD5.hashBytes(data);
			}
			
			Input.mouseCursor = "auto";
			
			if (! levelPacks[mode].levels[id]) {
				if (Main.anyInput) {
					FP.world = new Menu;
				}
				
				return;
			}
			
			if (! FP.focused && FP.stage.displayState != StageDisplayState.FULL_SCREEN) {
				wasUnfocused = true;
				return;
			}
			
			// Skip a frame on re-focusing so we don't handle mouse clicks
			if (wasUnfocused) {
				wasUnfocused = false;
				return;
			}
			
			if (Input.pressed(Key.ESCAPE)) {
				gotoMenu();
				return;
			}
			
			if (storyText || (gameOver && clickThrough)) {
				menuButton.hoverColor = Main.BLACK;
				muteButton.hoverColor = Main.BLACK;
				muteOverlay.normalColor = Main.BLACK;
			} else {
				menuButton.hoverColor = Main.PINK;
				muteButton.hoverColor = Main.PINK;
				muteOverlay.normalColor = Main.PINK;
			}
			
			if (storyText) {
				if (Main.anyInput) {
					FP.tween(storyText, {alpha: 0}, 30, {ease:Ease.sineOut});
					storyText = null;
				}
				
				menuButton.update();
				muteButton.update();
				muteOverlay.update();
				
				return;
			}
			
			if (Input.pressed(Key.E)) {
				editing = !editing;
				hasEdited = true;
				minClicks = 0;
				resetState();
			}
			
			if (Input.pressed(Key.G)) {
				addGraph(Logger.clickStats[md5]);
			}
			
			if (editing) {
				if (Input.check(Key.SHIFT)) {
					var dx:int = int(Input.pressed(Key.RIGHT)) - int(Input.pressed(Key.LEFT));
					var dy:int = int(Input.pressed(Key.DOWN)) - int(Input.pressed(Key.UP));
					
					if (dx || dy) {
						a = [];
						getType("cog", a);
						getType("heart", a);
						
						for each (var entity:Entity in a) {
							entity.x += dx * 4;
							entity.y += dy * 4;
						}
					}
				} else {
					hackBool = true;
					if (Input.check(Key.DOWN)) { makeHeart(0); }
					if (Input.check(Key.LEFT)) { makeHeart(1); }
					if (Input.check(Key.UP))   { makeHeart(2); }
					if (Input.check(Key.RIGHT)) { makeHeart(3); }
					if (hackBool) { lastHeart = null; }
				}
				
				if (Input.check(Key.SPACE)) { makeCog(); }
				if (Input.check(Key.BACKSPACE)) { removeUnderMouse(); }
				return;
			}
			
			if (gameOver) {
				if (clickThrough && Input.pressed(-1)) {
					FP.world = new Level(id+1, mode);
				}
			}
			
			var cog:Cog;
			
			a = [];
			getType("cog", a);
			
			for each (cog in a) {
				cog.over = false;
			}
			
			a = [];
			
			getType("heart", a);
			
			var incorrectCount:int = 0;
			
			somethingHighlighted = false;
			
			for each (var h:Heart in a) {
				h.highlight = false;
				if (h.rot != 0) {
					incorrectCount += 1;
				}
			}
			
			if (!hasEdited && !gameOver && incorrectCount == 0) {
				if (! Main.so.data.levels[md5]) Main.so.data.levels[md5] = {};
				
				Main.so.data.levels[md5].completed = true;
				
				var previousBest:int = Main.so.data.levels[md5].leastClicks;
				
				if (! Main.so.data.levels[md5].leastClicks
					|| clicks < Main.so.data.levels[md5].leastClicks)
				{
					Main.so.data.levels[md5].leastClicks = clicks;
				}
				
				Main.so.flush();
				
				gameOver = true;
				
				Audio.play("complete");
				
				Logger.endLevel(id, mode);
				
				time = -1;
				
				redoButton.disabled = true;
				undoButton.disabled = true;
				resetButton.disabled = true;
				
				var world:World = this;
				
				FP.alarm(149, function ():void {
					FP.alarm(50, function ():void {
						addCompletionUI(previousBest);
						
						clickThrough = true;
					});
					
					for each (h in a) {
						h.layer = -10;
						h.active = false;
						Spritemap(h.graphic).frame = 0;
						FP.tween(h, {x: 48, y: 48}, 60, {tweener:world, ease: Ease.sineIn});
						FP.tween(h.image, {scale: FP.width/3.0, originX: 4.5}, 60, {ease: Ease.sineIn});
					}
				});
			}
			
			if (!gameOver && reseting) {
				if (undoStack.length) {
					actuallyUndo();
				} else if (! Cog.rotating) {
					reseting = false;
					
					a = [];
					getType("cog", a);
				
					Cog.rotating = a[0];
				
					var f:Function = function ():void {
						Cog.rotating = null;
					}
				
					for each (cog in a) {
						FP.tween(cog.image, {angle: cog.image.angle+180}, 12, {complete: f});
						f = null;
					}
				}
			} else if (actions.length && !gameOver && ! Cog.rotating) {
				var e:* = actions.shift();
				
				if (e is Cog) {
					undoStack.push(e);
					undoButton.disabled = false;
					forgetFuture();
					clicks++;
					
					Cog(e).go();
					
					if (endGameHack) {
						actions.length = 0;
						
						if (e.x < 50) {
							FP.tween(black, {alpha: black.alpha + 0.21}, 16, function ():void {
								if (black.alpha >= 0.99) {
									gameOver = true;
									FP.alarm(120, function ():void {
										FP.world = new Intro(true);
									});
								}
							});
						}
					}
				} else if (e is Function) {
					e();
				}
			}
			
			var i:int;
			for (i = 0; i < 4; i++) {
				var step:int = gameOver ? 25 : 50;
				var beatTime:int = gameOver ? 10 : 10;
				var modTime:int = time % (step * 3);
				
				if (i == 0) {
					modTime = (time - step*0.5) % step;
				} else {
					modTime += step;
				}
				
				beating[i] = (modTime >= step*i && modTime < step*i+beatTime);
			}
			
			if (Input.pressed(Key.R)) {
				if (gameOver) FP.world = new Level(id, mode);
				else reset();
			}
			
			if (Input.pressed(Key.LEFT) && levelPacks[mode].levels[id-1]) FP.world = new Level(id-1, mode);
			if (Input.pressed(Key.RIGHT) && levelPacks[mode].levels[id+1]) FP.world = new Level(id+1, mode);
			
			if (gameOver && clickThrough) {
				super.update();
				return;
			}
			
			time++;
			
			super.update();
			
			clickCounter.text = "Clicks: " + clicks+"/"+minClicks;
		}
		
		public override function render (): void
		{
			if (editing) {
				for (var x:int = 4; x < FP.width; x += 8) {
					for (var y:int = 4; y < FP.width; y += 8) {
						Draw.rect(x-1+camera.x, y-1+camera.y, 2, 2, Main.GREY);
					}
				}
				
				x = mouseX - ((mouseX + 2) % 4) + 2;
				y = mouseY - ((mouseY + 2) % 4) + 2;
				
				Draw.rect(x-1, y-1, 2, 2, Main.PINK);
			}
			
			super.render();
			
			if (editing && Input.check(Key.SHIFT)) {
				Draw.rect(FP.width*0.5 - 1+camera.x, camera.y, 2, FP.height, Main.GREY);
				Draw.rect(camera.x, FP.height*0.5 - 1+camera.y, FP.width, 2, Main.GREY);
			}
		}
		
		private function addCompletionUI (previousBest:int): void
		{
			var md5:String = MD5.hashBytes(data);
			
			Main.so.data.lastPlayed = levelPacks[mode].md5[id+1];
			
			var next:Button = new Button(0, 0, new Text("Next level", 0, 0, {size: 8}), function ():void {
				FP.world = new Level(id+1, mode);
			}, null, false, true);
			
			var retry:Button = new Button(0, 0, new Text("Retry", 0, 0, {size: 8}), function ():void {
				FP.world = new Level(id, mode);
			}, null, false, true);
			
			var submit:Button = new Button(0, 0, new Text("Submit", 0, 0, {size: 8}), function ():void {
				//
			}, null, true, true);
			
			if (Main.expoMode) {
				submit = new Button(0, 0, new Text("New player", 0, 0, {size: 8}), function ():void {
					Main.resetPlayerData();
					FP.world = new Intro;
				}, null, false, true);
			}
			
			var menu:Button = new Button(0, 0, new Text("Main menu", 0, 0, {size: 8}), function ():void {
				FP.world = new Menu;
			}, null, false, true);
			
			var xButtonOffset:Number = 30;
			
			next.x = FP.width*0.5 + xButtonOffset - next.width*0.5;
			retry.x = FP.width*0.5 - xButtonOffset - retry.width*0.5;
			submit.x = FP.width*0.5 + xButtonOffset - submit.width*0.5;
			menu.x = FP.width*0.5 - xButtonOffset - menu.width*0.5;
			
			menu.y = submit.y = FP.height - 2 - retry.height;
			next.y = retry.y = menu.y - 2 - next.height;
			
			next.hoverColor = retry.hoverColor = submit.hoverColor = menu.hoverColor = Main.BLACK;
			next.normalColor = retry.normalColor = submit.normalColor = menu.normalColor = Main.WHITE;
			
			next.normalLayer = next.hoverLayer = next.layer = retry.normalLayer = retry.hoverLayer = retry.layer = -15;
			submit.normalLayer = submit.hoverLayer = submit.layer = menu.normalLayer = menu.hoverLayer = menu.layer = -15;
			
			// first score OR same score OR better score OR worse score
			// optimal score OR non-optimal OR beaten optimal
			
			var clickText:String = "<pink>Clicks: " + clicks + "</pink>";
			var previousBestText:String;
			var bestPossibleText:String;
			
			if (clicks <= minClicks) {
				clickText += "\nBest possible!";
			} else if (previousBestText && previousBest <= minClicks) {
				previousBestText += "\n(best possible)";
			} else {
				bestPossibleText = "Best possible: " + minClicks;
			}
			
			var t:Text = new Text(clickText, 1, 0, {align:"center", size:8, width: FP.width - 1, leading: 2});
			t.scrollX = t.scrollY = 0;
			
			t.setStyle("pink", {color: Main.PINK});
			
			if (previousBestText) t.text += "\n" + previousBestText;
			if (bestPossibleText) t.text += "\n" + bestPossibleText;
			
			t.richText = t.text;
			
			if (clicks < minClicks) {
				t.text = "Clicks: " + clicks + "\nNew record!";
				t.color = Main.PINK;
				
				var alert:String = "Completed " + mode + " level " + id + " (" + md5 + ") in " + clicks + " clicks (prev best: " + minClicks + ")";
				
				Logger.alert(alert);
			}
			
			var score:int = getScore(clicks);
			var prevBestScore:int = (previousBest) ? getScore(previousBest) : 0;
			
			var totalScore:int = Main.so.data.totalScore || 0;
			var totalScoreIncrease:int = 0;
			
			var t2:Text = new Text("", 1, 0, {align:"center", size:8, width: FP.width - 1, leading: 2, color: Main.BLACK});
			t2.scrollX = t2.scrollY = 0;
			
			t2.text = "Score: " + score;
			
			if (prevBestScore) {
				if (prevBestScore > score) {
					//t2.text += " (your best: " + prevBestScore + ")";
					t2.text += " (-" + (prevBestScore-score) + ")";
				} else if (prevBestScore < score) {
					totalScoreIncrease = score - prevBestScore;
					t2.text += " (+" + totalScoreIncrease + ")";
				} else {
					t2.text += " (your best)";
				}
			} else {
				totalScoreIncrease = score;
			}
			
			if (totalScoreIncrease) {
				totalScore += totalScoreIncrease;
				Main.so.data.totalScore = totalScore;
				Main.so.flush();
			}
			
			t2.text += "\n";
			
			t2.text += "Total score: "// + totalScore;
			
			/*if (totalScoreIncrease && totalScore != totalScoreIncrease) {
				t2.text += " (+" + totalScoreIncrease + ")";
			}*/
			
			var numberString:NumberString = new NumberString(totalScore-totalScoreIncrease, t2.text);
			
			numberString.bind(t2, "text");
			
			FP.tween(numberString, {value:totalScore}, 30);
			
			var graph:Stamp = addGraph(md5);
			
			var padding:Number = (next.y - 8 - t2.height - graph.height) / 3.0;
			
			if (Main.expoMode) {
				padding = (next.y - graph.height) / 2.0;
			}
			
			graph.y = padding + 8;
			
			t.y = graph.y + 2;
			
			t2.y = graph.y + graph.height + padding;
			
			addGraphic(t, -15);
			if (! Main.expoMode) addGraphic(t2, -15);
			add(next);
			add(retry);
			add(submit);
			add(menu);
		}
		
		public function getScore (n:int):int
		{
			var max:int = 50;
			
			var score:int = max - (n - minClicks);
			
			if (score < 0) score = 0;
			
			return score;
		}
		
		public function removeUnderMouse (): void
		{
			var x:int = mouseX - ((mouseX + 2) % 4) + 2;
			var y:int = mouseY - ((mouseY + 2) % 4) + 2;
			
			var a:Array = [];
			
			collideRectInto("heart", x - 1, y - 1, 2, 2, a);
			collideRectInto("cog", x - 1, y - 1, 2, 2, a);
			
			for each (var e:Entity in a) {
				remove(e);
			}
		}
		
		private static var hackBool:Boolean;
		private static var lastHeart:Point;
		
		public function makeHeart (rot:int): void
		{
			hackBool = false;
			
			var x:int = mouseX - ((mouseX + 2) % 4) + 2;
			var y:int = mouseY - ((mouseY + 2) % 4) + 2;
			
			if (lastHeart) {
				var dx:int = lastHeart.x - x;
				var dy:int = lastHeart.y - y;
				
				if ((dx % 8 != 0) || (dy % 8 != 0)) return;
				
				lastHeart.x = x;
				lastHeart.y = y;
			} else {
				lastHeart = new Point(x, y);
			}
			
			var a:Array = [];
			
			collideRectInto("heart", x - 3, y - 3, 6, 6, a);
			collideRectInto("cog", x - 3, y - 3, 6, 6, a);
			
			for each (var e:Entity in a) {
				remove(e);
			}
			
			add(new Heart(x, y, rot));
		}
		
		public function makeCog (): void
		{
			var x:int = mouseX - ((mouseX + 2) % 4) + 2;
			var y:int = mouseY - ((mouseY + 2) % 4) + 2;
			
			var a:Array = [];
			
			collideRectInto("heart", x - 7, y - 7, 14, 14, a);
			collideRectInto("cog", x - 7, y - 7, 14, 14, a);
			
			for each (var e:Entity in a) {
				remove(e);
			}
			
			add(new Cog(x, y));
		}
		
		public function addGraph (data:Object): Stamp
		{
			if (data is String) {
				data = Logger.clickStats[data];
			}
			
			if (! data) return null;
			
			var params:Object = {
				highlight: clicks,
				minX: 30,
				maxX: 50,
				height: 16,
				extraWidth: 1
			};
			
			var bitmap1:BitmapData = Graph.makeGraph(data, params);
			
			var bitmap2:BitmapData = new BitmapData(90, bitmap1.height + 24, false, Main.GREY);
			
			FP.rect.x = 1;
			FP.rect.y = 1;
			FP.rect.width = bitmap2.width - 2;
			FP.rect.height = bitmap2.height - 2;
			
			bitmap2.fillRect(FP.rect, Main.BLACK);
			
			FP.point.x = (bitmap2.width - bitmap1.width) * 0.5;
			FP.point.y = bitmap2.height - bitmap1.height - 1;
			
			bitmap2.copyPixels(bitmap1, bitmap1.rect, FP.point);
			
			var g:Stamp = new Stamp(bitmap2);
			g.scrollX = 0;
			g.scrollY = 0;
			
			g.x = (FP.width - bitmap2.width)*0.5;
			g.y = 12;
			
			addGraphic(g, -15);
			
			return g;
		}
	}
}

