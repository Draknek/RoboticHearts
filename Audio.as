package
{
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.utils.*;
	import flash.net.SharedObject;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import net.flashpunk.utils.Key;
	import net.flashpunk.FP;
	
	public class Audio
	{
		[Embed(source="audio/rotate.mp3")]
		public static var rotateSfx:Class;
		[Embed(source="audio/beat.mp3")]
		public static var beatSfx:Class;
		[Embed(source="audio/music.mp3")]
		public static var musicSfx:Class;
		
		public static var rotate:Sound = new rotateSfx;
		public static var complete:Sound = new beatSfx;
		public static var music:Sound = new musicSfx;
		
		public static var channels:Object = {};
		
		public static var v:Number = 0;
		
		private static var _mute:Boolean = false;
		private static var so:SharedObject;
		private static var menuItem:ContextMenuItem;
		
		public static function init (o:InteractiveObject):void
		{
			// Setup
			
			so = SharedObject.getLocal("audio", "/");
			
			_mute = so.data.mute;
			
			addContextMenu(o);
			
			if (o.stage) {
				addKeyListener(o.stage);
			} else {
				o.addEventListener(Event.ADDED_TO_STAGE, stageAdd);
			}
		}
		
		public static function play (sound:String):void
		{
			if (! _mute) {
				if (sound == "rotate") {
					if (! channels[sound]) {
						channels[sound] = Audio[sound].play(Math.random()*1000+500, int.MAX_VALUE, new SoundTransform(0));
					}
				
					v = 2;
				} else {
					Audio[sound].play(0, 2);
				}
			}
		}
		
		public static function startMusic ():void
		{
			if (! _mute) channels.music = music.play(0, int.MAX_VALUE);
		}
		
		public static function stopMusic ():void
		{
			if (channels.music) channels.music.stop();
		}
		
		public static function update ():void
		{
			if (! channels["rotate"]) return;
			
			var transform: SoundTransform = channels["rotate"].soundTransform;
			
			var n:Number = FP.clamp(v, 0, 1);
			
			transform.volume += (n - transform.volume) * 0.25;
		
			channels["rotate"].soundTransform = transform;
			
			v -= 0.04;
			
			trace(v);
			trace(":"+transform.volume);
		}
		
		// Getter and setter for mute property
		
		public static function get mute (): Boolean { return _mute; }
		
		public static function set mute (newValue:Boolean): void
		{
			if (_mute == newValue) return;
			
			_mute = newValue;
			
			menuItem.caption = _mute ? "Unmute" : "Mute";
			
			so.data.mute = _mute;
			so.flush();
		}
		
		// Implementation details
		
		private static function stageAdd (e:Event):void
		{
			addKeyListener(e.target.stage);
		}
		
		private static function addContextMenu (o:InteractiveObject):void
		{
			var menu:ContextMenu = o.contextMenu || new ContextMenu;
			
			menu.hideBuiltInItems();
			
			menuItem = new ContextMenuItem(_mute ? "Unmute" : "Mute");
			
			menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuListener);
			
			menu.customItems.push(menuItem);
			
			o.contextMenu = menu;
		}
		
		private static function addKeyListener (stage:Stage):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyListener);
		}
		
		private static function keyListener (e:KeyboardEvent):void
		{
			if (e.keyCode == Key.M) {
				mute = ! mute;
			}
		}
		
		private static function menuListener (e:ContextMenuEvent):void
		{
			mute = ! mute;
		}
	}
}
