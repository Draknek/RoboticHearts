package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.utils.*;
	import flash.ui.Mouse;
	
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
		
		[Embed(source="levels/simple.lvl", mimeType="application/octet-stream")]
		public static const LEVEL:Class;
		
		[Embed(source="levels/simple2.lvl", mimeType="application/octet-stream")]
		public static const LEVEL2:Class;
		
		[Embed(source="levels/simple3.lvl", mimeType="application/octet-stream")]
		public static const LEVEL3:Class;
		
		[Embed(source="levels/level4.lvl", mimeType="application/octet-stream")]
		public static const LEVEL4:Class;
		
		[Embed(source="levels/level5.lvl", mimeType="application/octet-stream")]
		public static const LEVEL5:Class;
		
		[Embed(source="levels/level7.lvl", mimeType="application/octet-stream")]
		public static const LEVEL6:Class;
		
		[Embed(source="levels/level6.lvl", mimeType="application/octet-stream")]
		public static const LEVEL7:Class;
		
		public static var levels:Array = [LEVEL, LEVEL2, LEVEL3, LEVEL4, LEVEL5, LEVEL6, LEVEL7];
		
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
			//add(new Button(8, 0, Button.UNDO, null));
			//add(new Button(16, 0, Button.REDO, null));
			
			if (id == 0) {
				addGraphic(new Text("Click cogs\nto mend hearts", 0, 8, {align:"center", size:8, width: 96}));
			}
			else if (id == 1) {
				addGraphic(new Text("R to reset", 0, 76, {align:"center", size:8, width: 96}));
			}
			
			var _data:ByteArray = new (levels[id]);
			
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
		
		/*public override function updateTweens ():void {
			if (Input.pressed(Key.SPACE)) super.updateTweens();
		}*/
		
		public static function index (i:int, j:int):int {
			return j*W + i;
		}
		
		public function get (i:int, j:int):Entity {
			return lookup[index(i, j)];
		}
		
		public function reset ():void
		{
			FP.world = new Level(id);
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
				Mouse.cursor = "auto";
				
				if (clickThrough && Input.mousePressed) {
					FP.world = new Level(id+1);
				}
				
				return;
			}
			
			var i:int;
			for (i = 0; i < 4; i++) {
				var step:int = 50;
				var beatTime:int = 10;
				var modTime:int = time % (step * 3);
				
				if (i == 0) {
					modTime = (time - step*0.5) % step;
				} else {
					modTime += step;
				}
				
				beating[i] = (modTime >= step*i && modTime < step*i+beatTime);
			}
			
			var a:Array = [];
			
			getType("heart", a);
			
			var incorrectCount:int = 0;
			
			for each (var h:Heart in a) {
				if (h.rot != 0) {
					incorrectCount += 1;
				}
			}
			
			if (incorrectCount == 0) {
				gameOver = true;
				
				Logger.endLevel(id);
				
				var t:Text = new Text("Level complete!", 0, 16, {align:"center", size:8, width: 95});
				var t2:Text = new Text("Clicks: " + clicks, 0, 40, {align:"center", size:8, width: 95});
				var t3:Text = new Text("Click for next level", 0, 64, {align:"center", size:8, width: 95});
				
				
				
				FP.tween(this, {}, 30, {complete: function ():void {
					addGraphic(t);
					addGraphic(t2);
					addGraphic(t3);
					
					if (id+1 == levels.length) {
						t3.text = "Game over\nYou win!"
					} else {
						clickThrough = true;
					}
				}});
				
				for each (h in a) {
					FP.tween(h, {x: 32, y:48}, 60, {tweener:this});
					FP.tween(h.image, {scale: 32, originX: 4.5}, 60);
				}
			}
			
			if (Input.pressed(Key.R)) reset();
			
			for (i = 0; i < levels.length; i++) {
				if (Input.pressed(Key.DIGIT_1 + i)) FP.world = new Level(i);
			}
			
			if (collidePoint("cog", mouseX, mouseY) || collidePoint("button", mouseX, mouseY)) {
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

