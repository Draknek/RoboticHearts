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
	import net.flashpunk.*;
	import net.flashpunk.tweens.misc.*;
	
	public class Audio
	{
		[Embed(source="audio/rotate.mp3")]
		public static var rotateSfx:Class;
		[Embed(source="audio/beat.mp3")]
		public static var beatSfx:Class;
		[Embed(source="audio/music.mp3")]
		public static var musicSfx:Class;
		
		public static var muteOverlay:Button;
		
		public static var rotate:Sound = new rotateSfx;
		public static var complete:Sound = new beatSfx;
		
		public static var music:Sfx = new Sfx(musicSfx);
		
		public static var volTween:VarTween = new VarTween;
		
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
			
			if (! Main.touchscreen && ! Main.expoMode) {
				addContextMenu(o);
			}
			
			if (o.stage) {
				addStageListeners(o.stage);
			} else {
				o.addEventListener(Event.ADDED_TO_STAGE, stageAdd);
			}
			
			FP.tweener.addTween(volTween);
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
			if (_mute) return;
			
			if (! music.playing) music.loop(music.volume);
			volTween.tween(music, "volume", 1.0, 30);
		}
		
		public static function stopMusic ():void
		{
			volTween.tween(music, "volume", 0.0, 30);
		}
		
		public static function resumeMusic ():void
		{
			if (_mute /*|| FP.world is Intro*/) return;
			
			if (! music.playing) music.loop(music.volume);
			
			volTween.tween(music, "volume", 1.0, 30);
		}
		
		public static function update ():void
		{
			if (! channels["rotate"]) return;
			
			var transform: SoundTransform = channels["rotate"].soundTransform;
			
			var n:Number = FP.clamp(v, 0, 1);
			
			transform.volume += (n - transform.volume) * 0.25;
		
			channels["rotate"].soundTransform = transform;
			
			v -= 0.04;
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
			
			if (muteOverlay) {
				muteOverlay.visible = _mute;
			}
			
			if (_mute) {
				stopMusic();
			} else { //if (! (FP.world is Menu)) {
				resumeMusic();
			}
		}
		
		public static function toggleMute ():void
		{
			mute = ! _mute;
		}
		
		// Implementation details
		
		private static function stageAdd (e:Event):void
		{
			addStageListeners(e.target.stage);
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
		
		private static function addStageListeners (stage:Stage):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyListener);
			stage.addEventListener(Event.ACTIVATE, focusGain);
			stage.addEventListener(Event.DEACTIVATE, focusLost);
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
		
		private static function focusGain (e:Event):void
		{
			resumeMusic();
		}
		
		private static function focusLost (e:Event):void
		{
			if (Main.touchscreen || FP.stage.displayState != StageDisplayState.FULL_SCREEN) {
				stopMusic();
			}
		}
	}
}

