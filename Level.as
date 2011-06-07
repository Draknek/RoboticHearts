package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
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
		public var wasUnfocused:Boolean = false;
		
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
			hasEdited = false;
			
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
		}
		
		public function Level (_id:int, _mode:String)
		{
			mode = _mode;
			
			id = _id;
			
			Logger.startLevel(id, mode);
			
			add(redoButton = new Button(0, 0, Button.REDO, redo, "Redo", true, true));
			add(undoButton = new Button(0, 0, Button.UNDO, undo, "Undo", true, true));
			add(resetButton = new Button(0, 0, Button.RESET, reset, "Reset", false, true));
			
			add(muteButton = new Button(0, 0, Button.AUDIO, Audio.toggleMute, "Mute", false, true));
			add(muteOverlay = new Button(0, 0, Button.AUDIO_MUTE, null, "Unmute", false, true));
			
			add(menuButton = new Button(0, 0, Button.MENU, gotoMenu, "Menu", false, true));
			
			muteButton.x = menuButton.x + menuButton.width;
			resetButton.x = muteButton.x + muteButton.width;
			undoButton.x = resetButton.x + resetButton.width;
			redoButton.x = undoButton.x + undoButton.width;
			muteOverlay.x = muteButton.x;
			
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
			levelIDDisplay.x = FP.width + 1 - levelIDDisplay.width;
			levelIDDisplay.scrollX = levelIDDisplay.scrollY = 0;
			addGraphic(levelIDDisplay);
			
			clickCounter = new Text("Clicks: 0", 0, FP.height - 10);
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
				text = text.split("\\n").join("\n\n");
				
				storyText = new Text(text, 1, 0, {width: FP.width, align:"center", wordWrap:true, leading: 3});
				
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
			}
			
			var _data:ByteArray = levelPacks[mode].levels[id];
			
			var md5:String = MD5.hashBytes(_data);
			
			addGraph(Logger.clickStats[md5]);
			
			if (_data) {
				setWorldData(_data);
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
		
		public override function update (): void
		{
			camera.x = -(FP.width - 96)*0.5;
			camera.y = -(FP.height - 96)*0.5;
			
			Input.mouseCursor = "auto";
			
			if (! levelPacks[mode].levels[id]) {
				if (Input.mousePressed || Input.pressed(-1)) {
					FP.world = new Menu;
				}
				
				return;
			}
			
			if (! FP.focused) {
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
			
			if (storyText) {
				if (Input.mousePressed || Input.pressed(-1)) {
					FP.tween(storyText, {alpha: 0}, 30, {ease:Ease.sineOut});
					storyText = null;
				}
				
				return;
			}
			
			if (Input.pressed(Key.E)) {
				editing = !editing;
				hasEdited = true;
				minClicks = 0;
				resetState();
			}
			
			if (editing) {
				if (Input.check(Key.DOWN)) { makeHeart(0); }
				if (Input.check(Key.LEFT)) { makeHeart(1); }
				if (Input.check(Key.UP))   { makeHeart(2); }
				if (Input.check(Key.RIGHT)) { makeHeart(3); }
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
			
			var a:Array;
			
			a = [];
			getType("cog", a);
			
			for each (cog in a) {
				cog.over = false;
			}
			
			a = [];
			
			getType("heart", a);
			
			var incorrectCount:int = 0;
			
			for each (var h:Heart in a) {
				h.highlight = false;
				if (h.rot != 0) {
					incorrectCount += 1;
				}
			}
			
			if (!hasEdited && !gameOver && incorrectCount == 0) {
				var md5:String = MD5.hashBytes(data);
				
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
				
				var world:World = this;
				
				FP.alarm(50, function ():void {
					FP.alarm(50, function ():void {
						var buttons:Array = [];
						
						world.getClass(Button, buttons);
						
						world.removeList(buttons);
						
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
			
			for (i = 0; i < 10; i++) {
				if (Input.pressed(Key.DIGIT_1 + i)) FP.world = new Level(i, mode);
			}
			
			if (gameOver && clickThrough) {
				super.update();
				return;
			}
			
			time++;
			
			super.update();
			
			if (gameOver) {
				Input.mouseCursor = "auto";
			}
			
			clickCounter.text = "Clicks: " + clicks+"/"+minClicks;
		}
		
		public override function render (): void
		{
			if (editing) {
				for (var x:int = 4; x < FP.width; x += 8) {
					for (var y:int = 4; y < FP.width; y += 8) {
						Draw.rect(x-1, y-1, 2, 2, Main.GREY);
					}
				}
				
				x = mouseX - ((mouseX + 2) % 4) + 2;
				y = mouseY - ((mouseY + 2) % 4) + 2;
				
				Draw.rect(x-1, y-1, 2, 2, Main.PINK);
			}
			
			super.render();
		}
		
		private function addCompletionUI (previousBest:int): void
		{
			var md5:String = MD5.hashBytes(data);
			
			var next:Button = new Button(0, 0, new Text("Next level", 0, 0, {size: 8}), function ():void {
				FP.world = new Level(id+1, mode);
			}, null, false, true);
			
			var retry:Button = new Button(0, 0, new Text("Retry", 0, 0, {size: 8}), function ():void {
				FP.world = new Level(id, mode);
			}, null, false, true);
			
			next.x = (FP.width - next.width)*0.5;
			retry.x = (FP.width - retry.width)*0.5;
			
			retry.y = FP.height - 4 - retry.height;
			next.y = retry.y - 4 - next.height;
			
			next.hoverColor = retry.hoverColor = Main.BLACK;
			next.normalColor = retry.normalColor = Main.WHITE;
			next.normalLayer = next.hoverLayer = next.layer = retry.normalLayer = retry.hoverLayer = retry.layer = -15;
			
			// first score OR same score OR better score OR worse score
			// optimal score OR non-optimal OR beaten optimal
			
			var clickText:String = "Clicks: " + clicks;
			var previousBestText:String;
			var bestPossibleText:String;
			
			if (! previousBest || previousBest == clicks) {
				previousBestText = null;
			} else if (previousBest < clicks) {
				previousBestText = "Your best: " + previousBest;
			} else {
				previousBestText = "Previous best: " + previousBest;
			}
			
			if (clicks <= minClicks) {
				clickText += "\n(best possible)";
			} else if (previousBestText && previousBest <= minClicks) {
				previousBestText += "\n(best possible)";
			} else {
				bestPossibleText = "Best possible: " + minClicks;
			}
			
			var t:Text = new Text(clickText, 0, 0, {align:"center", size:8, width: FP.width - 1});
			t.scrollX = t.scrollY = 0;
			
			if (previousBestText) t.text += "\n\n" + previousBestText;
			if (bestPossibleText) t.text += "\n\n" + bestPossibleText;
			
			if (clicks < minClicks) {
				t.text = "Clicks: " + clicks + "\n\nWell done! You used\n" + (minClicks - clicks) + "\nfewer clicks than I\nthought were needed!";
				
				var alert:String = "Completed " + mode + " level " + id + " (" + md5 + ") in " + clicks + " clicks (prev best: " + minClicks + ")";
				
				Logger.alert(alert);
			}
			
			var graphStop:int = 0;//27+8;
			
			var space:Number = next.y - t.height - graphStop;
			
			t.y = space * 0.5 + graphStop;
			
			addGraphic(t, -15);
			add(next);
			add(retry);
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
		
		public function makeHeart (rot:int): void
		{
			var x:int = mouseX - ((mouseX + 2) % 4) + 2;
			var y:int = mouseY - ((mouseY + 2) % 4) + 2;
			
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
		
		public function addGraph (data:Object): Boolean
		{
			return false;
			
			if (! data) return false;
			
			var yourClicks:int = clicks;
			
			if (data[yourClicks]) data[yourClicks]++;
			else data[yourClicks] = 1;
			
			var i:int
			
			const MAX_WIDTH:int = 60;
			
			var maxClicks:int = 0;
			var maxHeight:int = 1;
			
			for (var key:String in data) {
				if (int(key) > MAX_WIDTH) {
					data[MAX_WIDTH] = int(data[key]) + int(data[MAX_WIDTH]);
					delete data[key];
					key = String(MAX_WIDTH);
				}
				
				if (int(key) > maxClicks) maxClicks = int(key);
				if (data[key] > maxHeight) maxHeight = data[key];
			}
			
			var width:int = Math.ceil(maxClicks/10)*10;
			if (width < 30) width = 30;
			var height:int = 16;
			
			FP.rect.x = 1;
			FP.rect.y = 1;
			FP.rect.width = width + 2;
			FP.rect.height = height + 2 + 7;
			
			var bitmap:BitmapData = new BitmapData(FP.rect.width + 2, FP.rect.height + 2, false, Main.GREY);
			
			bitmap.fillRect(FP.rect, Main.BLACK);
			
			FP.rect.width = 1;
			
			var scale:Number = height / maxHeight;
			
			if (scale > 4) scale = 4;
			
			for (i = 1; i <= maxClicks; i++) {
				FP.rect.height = data[i] * scale;
				FP.rect.x = i + 1;
				FP.rect.y = height + 2 - FP.rect.height;
				
				var c:uint = Main.WHITE;
				
				if (i == yourClicks) c = Main.PINK;
				
				bitmap.fillRect(FP.rect, c);
			}
			
			for (i = 10; i <= width; i += 10) {
				bitmap.setPixel32(i + 1, height + 2, Main.GREY);
			}
			
			var text:Text = new Text("Clicks", 0, height + 1);
			
			text.x = (bitmap.width - text.width)*0.5 + 1;
			
			text.render(bitmap, FP.zero, FP.zero);
			
			var g:Graphic = new Stamp(bitmap);
			g.scrollX = 0;
			g.scrollY = 0;
			
			addGraphic(g, -15, (FP.width - bitmap.width)*0.5, 8);
			
			return true;
		}
	}
}

