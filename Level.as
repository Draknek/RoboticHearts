package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	import flash.utils.*;
	import flash.ui.Mouse;
	
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
			
			var cogs:Array = [];
			var hearts:Array = [];
			
			var e:Entity;
			
			getType("cog", cogs);
			getType("heart", hearts);
			
			b.writeInt(cogs.length);
			
			for each (e in cogs) {
				b.writeInt((e.x - 4) / 8);
				b.writeInt((e.y - 4) / 8);
			}
			
			b.writeInt(hearts.length);
			
			for each (e in hearts) {
				b.writeInt((e.x) / 8);
				b.writeInt((e.y) / 8);
				b.writeInt(Heart(e).rot);
			}
			
			return b;
		}
		
		public override function setWorldData (b: ByteArray): void {
			resetState();
			minClicks = 0;
			hasEdited = false;
			
			b.position = 0;
			
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
				add(new Cog(x, y));
			}
			
			l = b.readInt();
			
			for (i = 0; i < l; i++) {
				x = b.readInt();
				y = b.readInt();
				rot = b.readInt();
				add(new Heart(x, y, rot));
			}
		}
		
		public function Level (_id:int, _mode:String)
		{
			mode = _mode;
			
			id = _id;
			
			Logger.startLevel(id, mode);
			
			add(redoButton = new Button(0, 0, Button.REDO, redo, "Redo", true));
			add(undoButton = new Button(0, 0, Button.UNDO, undo, "Undo", true));
			add(resetButton = new Button(0, 0, Button.RESET, reset, "Reset"));
			
			add(muteButton = new Button(0, 0, Button.AUDIO, Audio.toggleMute, "Mute"));
			add(muteOverlay = new Button(0, 0, Button.AUDIO_MUTE, null, "Unmute"));
			
			add(menuButton = new Button(0, 0, Button.MENU, gotoMenu, "Menu"));
			
			muteButton.x = menuButton.x + menuButton.width;
			resetButton.x = muteButton.x + muteButton.width;
			undoButton.x = resetButton.x + resetButton.width;
			redoButton.x = undoButton.x + undoButton.width;
			muteOverlay.x = muteButton.x;
			
			muteOverlay.normalColor = Main.PINK;
			muteOverlay.hoverColor = Main.WHITE;
			muteOverlay.visible = Audio.mute;
			
			if (levelPacks[mode].levels[id+1]) {
				add(new Button(96-8, 96-10, Button.SKIP, skip, "Skip level"));
			}
			
			var modeCode:String = "";
			
			if (mode == "perfection") modeCode = "P";
			
			var levelIDDisplay:Text = new Text(modeCode+(id+1), 0, -1);
			levelIDDisplay.x = 96 + 1 - levelIDDisplay.width;
			addGraphic(levelIDDisplay);
			
			clickCounter = new Text("0", 0, 86);
			addGraphic(clickCounter);
			
			if (mode == "normal") {
				if (id == 0) {
					addGraphic(new Text("Click cogs to\nbrighten hearts", 0, 68, {align:"center", size:8, width: 96}));
				}
				else if (id == 1) {
					addGraphic(new Text("Make all upright", 0, 76, {align:"center", size:8, width: 96}));
				}
				else if (id == 2) {
					addGraphic(new Text("R to reset", 0, 76, {align:"center", size:8, width: 96}));
				}
			}
			
			if (levelPacks[mode].story && levelPacks[mode].story[id] && levelPacks[mode].story[id].length) {
				var text:String = levelPacks[mode].story[id];
				text = text.split("\\n").join("\n\n");
				
				storyText = new Text(text, 1, 0, {width: 96, align:"center", wordWrap:true});
				
				storyText.y = (96 - storyText.height) * 0.5;
				
				var bitmap:BitmapData = new BitmapData(96, 96, false, Main.PINK);
				
				storyText.render(bitmap, FP.zero, camera);
				
				storyText = new Image(bitmap);
				
				addGraphic(storyText, -9);
			}
			
			var oldScreen:Image = new Image(FP.buffer.clone());
			
			addGraphic(oldScreen, -10);
			
			FP.tween(oldScreen, {alpha: 0}, 30, {ease:Ease.sineOut, tweener:this});
			
			if (levelPacks[mode].special[id]) {
				var flags:int = levelPacks[mode].special[id];
				
				if (flags & 1) mirrorX = true;
				if (flags & 2) mirrorY = true;
				if (flags & 4) stopSpinHack = true;
			}
			
			var _data:ByteArray = levelPacks[mode].levels[id];
			
			if (_data) {
				setWorldData(_data);
				minClicks = levelPacks[mode].minClicksArray[id];
				return;
			}
			
			updateLists();
			
			removeAll();
			
			addGraphic(Image.createRect(96, 96, Main.PINK));
			
			var t:Text = new Text("And that is the story\n\nOf these robotic hearts of mine\n\n\nThanks for playing!", 0, 0, {width: 96, wordWrap: true, align: "center"});
			
			t.y = (96 - t.height)*0.5;
			
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
			if (! levelPacks[mode].levels[id]) {
				if (Input.mousePressed || Input.pressed(-1)) {
					FP.world = new Menu;
				}
				
				Mouse.cursor = "auto";
				return;
			}
			
			if (! FP.focused) {
				Mouse.cursor = "auto";
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
			}
			
			if (storyText) {
				if (Input.mousePressed || Input.pressed(-1)) {
					FP.tween(storyText, {alpha: 0}, 30, {ease:Ease.sineOut});
					storyText = null;
				}
				Mouse.cursor = "auto";
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
				Mouse.cursor = "auto";
				return;
			}
			
			if (gameOver) {
				if (clickThrough && (Input.mousePressed || Input.pressed(-1))) {
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
				
				var t:Text = new Text("Clicks: " + clicks, 0, 24, {align:"center", size:8, width: 95});
				var t2:Text = new Text("Previous best: " + previousBest, 0, 40, {align:"center", size:8, width: 95});
				var t3:Text = new Text("Best possible: " + minClicks, 0, 56, {align:"center", size:8, width: 95});
				var t4:Text = new Text("Click to continue", 0, 86, {align:"center", size:8, width: 95});
				
				if (! previousBest || previousBest == clicks) {
					t2.text = "";
					t.y += 8;
					t3.y -= 8;
				} else if (previousBest < clicks) {
					t2.text = "Your best: " + previousBest;
				}
				
				if (clicks <= minClicks) {
					t.text += "\n(best possible)";
					
					t3.text = "";
					
					if (t2.text) {
						t.y = 28;
						t2.y = 52;
					} else {
						t.y = 36;
					}
				} else if (t2.text && previousBest <= minClicks) {
					t2.text += "\n(best possible)";
					
					t3.text = "";
					
					t.y = 28;
					t2.y = 44;
				}
				
				if (clicks < minClicks) {
					t2.text = ""
					t3.text = ""
					
					t.text = "Clicks: " + clicks + "\n\nWell done! You used\n" + (minClicks - clicks) + "\nfewer clicks than I\nthought were needed!";
					
					t.y = (88 - t.height)*0.5;
					
					var alert:String = "Completed " + mode + " level " + id + " (" + md5 + ") in " + clicks + " clicks";
					
					Logger.alert(alert);
				}
				
				var world:World = this;
				
				FP.tween(this, {}, 50, {complete: function ():void {
					FP.tween(this, {}, 30, {complete: function ():void {
						addGraphic(t, -15);
						addGraphic(t2, -15);
						addGraphic(t3, -15);
						addGraphic(t4, -15);
					
						clickThrough = true;
					}});
					
					for each (h in a) {
						h.layer = -10;
						h.active = false;
						FP.tween(h, {x: 32, y:48}, 60, {tweener:world, ease: Ease.sineIn});
						FP.tween(h.image, {scale: 32, originX: 4.5}, 60, {ease: Ease.sineIn});
					}
				}});
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
				Mouse.cursor = "auto";
				return;
			}
			
			if (!gameOver && collidePoint("cog", mouseX, mouseY) || collidePoint("button", mouseX, mouseY)) {
				Mouse.cursor = "button";
			} else {
				Mouse.cursor = "auto";
			}
			
			time++;
			
			super.update();
			
			clickCounter.text = clicks+"/"+minClicks;
		}
		
		public override function render (): void
		{
			super.render();
		}
		
		public function removeUnderMouse (): void
		{
			var x:int = mouseX / 8;
			var y:int = mouseY / 8;
			
			var e:Entity = collidePoint("heart", x*8+4, y*8+4);
			if (e) remove(e);
			e = collidePoint("cog", x*8+4, y*8+4);
			if (e) remove(e);
		}
		
		public function makeHeart (rot:int): void
		{
			var x:int = mouseX / 8;
			var y:int = mouseY / 8;
			
			var e:Entity = collidePoint("heart", x*8+4, y*8+4);
			if (e) remove(e);
			e = collidePoint("cog", x*8+4, y*8+4);
			if (e) remove(e);
			
			add(new Heart(x, y, rot));
		}
		
		public function makeCog (): void
		{
			var x:int = (mouseX - 4) / 8;
			var y:int = (mouseY - 4) / 8;
			
			var e:Entity = collidePoint("heart", x*8+4, y*8+4);
			if (e) remove(e);
			e = collidePoint("heart", x*8+12, y*8+4);
			if (e) remove(e);
			e = collidePoint("heart", x*8+4, y*8+12);
			if (e) remove(e);
			e = collidePoint("heart", x*8+12, y*8+12);
			if (e) remove(e);
			e = collidePoint("cog", x*8+4, y*8+4);
			if (e) remove(e);
			e = collidePoint("cog", x*8+12, y*8+4);
			if (e) remove(e);
			e = collidePoint("cog", x*8+4, y*8+12);
			if (e) remove(e);
			e = collidePoint("cog", x*8+12, y*8+12);
			if (e) remove(e);
			
			add(new Cog(x, y));
		}
	}
}

