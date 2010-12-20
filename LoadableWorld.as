package
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.utils.ByteArray;
	import flash.net.FileReference;
	
	import net.flashpunk.FP;
	import net.flashpunk.World;
	import net.flashpunk.utils.Key;
	
	public class LoadableWorld extends World
	{
		// Must be implemented by superclass
		
		public function getWorldData (): *
		{
			return "";
		}
		
		public function setWorldData (data: ByteArray): void {}
		
		public function undo (): void {}
		public function redo (): void {}
		
		// Must be called even if overridden
		
		public override function begin (): void
		{
			FP.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		}
		
		public override function end (): void
		{
			FP.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		}
		
		// Private functions
		
		private function keyDownListener (e:KeyboardEvent): void
		{
			if (e.ctrlKey || e.shiftKey)
			{
				if (e.keyCode == Key.S)
				{
					save();
				}
				else if (e.keyCode == Key.O)
				{
					load();
				}
				else if (e.keyCode == Key.Z)
				{
					if (e.ctrlKey && e.shiftKey) {
						redo();
					} else {
						undo();
					}
				}
				else if (e.keyCode == Key.Y)
				{
					redo();
				}
			}
		}
		
		private function save (): void
		{
			new FileReference().save(getWorldData());
		}
		
		private function load (): void
		{
			trace("load");
			var file: FileReference = new FileReference();
			file.addEventListener(Event.SELECT, fileSelect);
			file.browse();
			
			function fileSelect (event:Event):void {
				trace("fileselect");
				//var file:FileReference = event.target as FileReference;
				file.addEventListener(Event.COMPLETE, loadComplete);
				file.load();
			}

			function loadComplete (event:Event):void {
				trace("loadcomplete");
				//var file:FileReference = FileReference(event.target);
				setWorldData(file.data);
			}
		}
		
		
	}
}
