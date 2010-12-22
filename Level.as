package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
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
		
		public var id:int;
		
		public var beating:Array = [0,0,0,0];
		
		public var time:int = 0;
		public var clicks:int = 0;
		
		public var undoStack:Array = [];
		public var redoStack:Array = [];
		
		public var actions:Array = [];
		
		public var undoButton:Button;
		public var redoButton:Button;
		
		public var reseting:Boolean = false;
		
		[Embed(source="levels/all.lvl", mimeType="application/octet-stream")]
		public static const LEVELS:Class;
		
		public static var levels:Array;
		
		public static function loadLevels():void
		{
			levels = [];
			
			var data:ByteArray = new LEVELS;
			
			data.position = 0;
			
			var levelCount:int = data.readInt();
			
			for (var i:int = 0; i < levelCount; i++) {
				var levelSize:int = data.readInt();
				
				var levelData:ByteArray = new ByteArray;
			
				data.readBytes(levelData, 0, levelSize);
				
				levels.push(levelData);
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
			forgetPast();
			forgetFuture();
			actions.length = 0;
			
			b.position = 0;
			
			data = b;
			
			removeAll();
			
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
		
		public function Level (_id:int = 0)
		{
			id = _id;
			
			Logger.startLevel(id);
			
			add(new Button(0, 0, Button.RESET, reset));
			add(undoButton = new Button(8, 0, Button.UNDO, undo, true));
			add(redoButton = new Button(16, 0, Button.REDO, redo, true));
			
			var levelIDDisplay:Text = new Text((id+1)+"", 0, -1);
			levelIDDisplay.x = 96 + 1 - levelIDDisplay.width;
			addGraphic(levelIDDisplay);
			
			if (id == 0) {
				addGraphic(new Text("Click cogs\nto mend hearts", 0, 8, {align:"center", size:8, width: 96}));
			}
			else if (id == 1) {
				addGraphic(new Text("Make all upright", 0, 76, {align:"center", size:8, width: 96}));
			}
			else if (id == 2) {
				addGraphic(new Text("R to reset", 0, 76, {align:"center", size:8, width: 96}));
			}
			
			var _data:ByteArray = levels[id];
			
			if (_data) {
				setWorldData(_data);
				return;
			}
			
			var e:Entity;
			var x:int = 5;
			var y:int = 5;
			
			e = new Cog(x, y);
			lookup[index(x,y)] = e;
			lookup[index(x+1,y)] = e;
			lookup[index(x,y+1)] = e;
			lookup[index(x+1,y+1)] = e;
			add(e);
			
			for (x = 0; x < W; x++) {
				for (y = 0; y < H; y++) {
					if (get(x, y)) { continue; }
					
					/*if (x != W-1 && y != H-1 && !get(x+1, y) && !get(x, y+1) && FP.rand(4)==0) {
						e = new Cog(x, y);
						lookup[index(x,y)] = e;
						lookup[index(x+1,y)] = e;
						lookup[index(x,y+1)] = e;
						lookup[index(x+1,y+1)] = e;
					} else*/ {
						e = new Heart(x, y);
						lookup[index(x,y)] = e;
					}
					
					add(e);
				}
			}
			
			updateLists();
			
			data = getWorldData();
		}
		
		public static function index (i:int, j:int):int {
			return j*W + i;
		}
		
		public function get (i:int, j:int):Entity {
			return lookup[index(i, j)];
		}
		
		public function reset ():void
		{
			reseting = true;
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
			
			undoStack.push(cog);
			
			undoButton.disabled = (undoStack.length == 0);
			redoButton.disabled = (redoStack.length == 0);
		}
		
		public override function update (): void
		{
			if (Input.pressed(Key.E)) editing = !editing;
			
			if (editing) {
				if (Input.check(Key.DOWN)) { makeHeart(0); }
				if (Input.check(Key.LEFT)) { makeHeart(1); }
				if (Input.check(Key.UP))   { makeHeart(2); }
				if (Input.check(Key.RIGHT)) { makeHeart(3); }
				if (Input.check(Key.SPACE)) { makeCog(); }
				return;
			}
			
			if (gameOver) {
				if (clickThrough && Input.mousePressed) {
					FP.world = new Level(id+1);
				}
			}
			
			var a:Array;
			
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
				
					for each (var cog:Cog in a) {
						FP.tween(cog.image, {angle: cog.image.angle+180}, 12, {complete: f});
						f = null;
					}
				}
			} else if (actions.length && ! Cog.rotating) {
				var e:* = actions.shift();
				
				if (e is Cog) {
					undoStack.push(e);
					undoButton.disabled = false;
					forgetFuture();
					
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
			
			a = [];
			
			getType("heart", a);
			
			var incorrectCount:int = 0;
			
			for each (var h:Heart in a) {
				h.highlight = false;
				if (h.rot != 0) {
					incorrectCount += 1;
				}
			}
			
			if (!gameOver && incorrectCount == 0) {
				var md5:String = MD5.hashBytes(data);
				
				if (! Main.so.data.levels[md5]) Main.so.data.levels[md5] = {};
				
				Main.so.data.levels[md5].completed = true;
				
				Main.so.flush();
				
				gameOver = true;
				
				time = -1;
				
				Logger.endLevel(id);
				
				var t:Text = new Text("Level complete!", 0, 16, {align:"center", size:8, width: 95});
				var t2:Text = new Text("Clicks: " + clicks, 0, 40, {align:"center", size:8, width: 95});
				var t3:Text = new Text("Click for next level", 0, 64, {align:"center", size:8, width: 95});
				
				var world:World = this;
				
				FP.tween(this, {}, 50, {complete: function ():void {
					FP.tween(this, {}, 30, {complete: function ():void {
						addGraphic(t);
						addGraphic(t2);
						addGraphic(t3);
					
						if (id+1 >= levels.length) {
							t3.text = "Game over\nYou win!"
						} else {
							clickThrough = true;
						}
					}});
					
					for each (h in a) {
						h.active = false;
						FP.tween(h, {x: 32, y:48}, 60, {tweener:world, ease: Ease.sineIn});
						FP.tween(h.image, {scale: 32, originX: 4.5}, 60, {ease: Ease.sineIn});
					}
				}});
			}
			
			if (Input.pressed(Key.ESCAPE)) {
				FP.world = new Menu;
			}
			
			if (Input.pressed(Key.R)) {
				if (gameOver) FP.world = new Level(id);
				else reset();
			}
			
			if (Input.pressed(Key.N)) FP.world = new Level(id+1);
			
			for (i = 0; i < levels.length; i++) {
				if (Input.pressed(Key.DIGIT_1 + i)) FP.world = new Level(i);
			}
			
			if (!gameOver && collidePoint("cog", mouseX, mouseY) || collidePoint("button", mouseX, mouseY)) {
				Mouse.cursor = "button";
			} else {
				Mouse.cursor = "auto";
			}
			
			time++;
			
			super.update();
		}
		
		public override function render (): void
		{
			super.render();
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

