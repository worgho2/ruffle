package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	// Objects whose scrollRect is scrolled past their own position: each shows
	// the last 100 px of its 600 px content at x = 50, so its visible area is
	// x = 50..150. Hit tests use that area, and the objects are rendered.
	public class Test extends Sprite {
		private var frames:int = 0;
		private var objects:Array;
		private var inView:Shape, shifted:Shape;

		function Test() {
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0xFF0000);
			shape.graphics.drawRect(0, 0, 500, 20);
			shape.graphics.beginFill(0x00FF00);
			shape.graphics.drawRect(500, 0, 100, 20);
			shape.graphics.endFill();

			var data:BitmapData = new BitmapData(600, 20, false, 0xFF0000);
			data.fillRect(new Rectangle(500, 0, 100, 20), 0x0000FF);
			var bitmap:Bitmap = new Bitmap(data);

			var text:TextField = new TextField();
			text.width = 600;
			text.height = 20;
			text.background = true;
			text.backgroundColor = 0xFF00FF;

			objects = [shape, bitmap, text];
			var y:int = 5;
			for each (var o:DisplayObject in objects) {
				o.x = 50;
				o.y = y;
				o.scrollRect = new Rectangle(500, 0, 100, 20);
				addChild(o);
				y += 30;
			}

			// Where the shape is shown, and where it would be if the scroll
			// offset moved its bounds.
			inView = box(60, 5);
			shifted = box(-440, 5);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function box(x:Number, y:Number):Shape {
			var s:Shape = new Shape();
			s.graphics.beginFill(0x000000);
			s.graphics.drawRect(0, 0, 10, 10);
			s.graphics.endFill();
			s.x = x;
			s.y = y;
			s.visible = false;
			addChild(s);
			return s;
		}

		private function onEnterFrame(e:Event):void {
			if (++frames != 3) {
				return;
			}
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			for each (var o:DisplayObject in objects) {
				var name:String = String(o);
				trace(name + ".hitTestPoint(60, " + (o.y + 5) + ") = " + o.hitTestPoint(60, o.y + 5));
				trace(name + ".hitTestPoint(60, " + (o.y + 5) + ", true) = " + o.hitTestPoint(60, o.y + 5, true));
				trace(name + ".hitTestPoint(-440, " + (o.y + 5) + ") = " + o.hitTestPoint(-440, o.y + 5));
				trace(name + ".getBounds(stage) = " + o.getBounds(stage));
			}
			var first:DisplayObject = objects[0];
			trace("shape.hitTestObject(inView) = " + first.hitTestObject(inView));
			trace("inView.hitTestObject(shape) = " + inView.hitTestObject(first));
			trace("shape.hitTestObject(shifted) = " + first.hitTestObject(shifted));
			trace("shifted.hitTestObject(shape) = " + shifted.hitTestObject(first));
		}
	}
}
