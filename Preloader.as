
package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.utils.*;
	
	import flash.display.LoaderInfo;
	import flash.utils.getDefinitionByName;

	public class Preloader extends World
	{
		private var text: Text;
		
		private var nextClassName: String;
		
		private var mustClick: Boolean;
		
		public function Preloader (_next: String, _mustClick: Boolean = true)
		{
			nextClassName = _next;
			
			mustClick = _mustClick;
			
			text = new Text("0%", 0, 0, 300);
			
			text.align = "center";
			
			text.x = (FP.width - text.width) * 0.5;
			text.y = FP.height * 0.5 + 20;
		}

		public override function update (): void
		{
			if (hasLoaded())
			{
				if (mustClick)
				{
					if (Input.mousePressed)
					{
						startup();
					}
				}
				else
				{
					startup();
				}
			}
		}
		
		public override function render (): void
		{
			if (mustClick && hasLoaded())
			{
				text.scale = 2;
				
				text.text = "Click to start";
			
				text.x = (FP.width - text.width) * 0.5;
				text.y = (FP.height - text.height) * 0.5;
			}
			else
			{
				var w: int = FP.width * 0.8;
				
				FP.rect.x = (FP.width - w - 4) * 0.5;
				FP.rect.y = FP.height * 0.5 - 12;
				FP.rect.width = w + 4;
				FP.rect.height = 24;
				
				FP.buffer.fillRect(FP.rect, 0xFFFFFFFF);
				
				var p:Number = (FP.stage.loaderInfo.bytesLoaded / FP.stage.loaderInfo.bytesTotal);
				
				FP.rect.x = (FP.width - w) * 0.5;
				FP.rect.y = FP.height * 0.5 - 10;
				FP.rect.width = p * w;
				FP.rect.height = 20;
				
				FP.buffer.fillRect(FP.rect, 0xFF000000);
				
				text.text = int(p * 100) + "%";
			}
			
			FP.point.x = 0;
			FP.point.y = 0;
			text.render(FP.point, FP.zero);
		}
		
		private function hasLoaded (): Boolean {
			return (FP.stage.loaderInfo.bytesLoaded >= FP.stage.loaderInfo.bytesTotal);
		}
		
		private function startup (): void
		{
			var worldClass:Class = getDefinitionByName(nextClassName) as Class;
			
			FP.world = new worldClass() as World;
		}
	}
}


