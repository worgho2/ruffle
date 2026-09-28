package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	// How BlendMode.ALPHA treats source pixels whose alpha is 0, for a bitmap
	// and for a vector fill, both in BitmapData.draw and on a LAYER parent.
	//
	// The bitmap and shape sources are 30x10: [0,10) opaque, [10,20) half
	// alpha, [20,30) alpha 0; [30,40) is outside the source. Every target
	// starts opaque, so the probes at x = 5, 25 and 35 show what the opaque,
	// transparent and undrawn parts did. The half alpha band and the middle of
	// the gradient ramp are not probed: their exact rounding is not the point.
	public class Test extends Sprite {
		private static const SOLID_PROBES:Array = [5, 25, 35];
		private static const GRADIENT_PROBES:Array = [5, 15, 35];

		public function Test() {
			probe("draw bitmap", drawOnto(bitmapSource()), SOLID_PROBES);
			probe("draw shape", drawOnto(shapeSource()), SOLID_PROBES);
			probe("draw bitmap clipped", drawOnto(bitmapSource(), new Rectangle(0, 0, 22, 10)), SOLID_PROBES);
			probe("layer bitmap", layerSnapshot(bitmapSource(), 0), SOLID_PROBES);
			probe("layer shape", layerSnapshot(shapeSource(), 12), SOLID_PROBES);
			probe("draw gradient", drawOnto(gradientSource()), GRADIENT_PROBES);
			probe("layer gradient", layerSnapshot(gradientSource(), 24), GRADIENT_PROBES);
		}

		private function bitmapSource():DisplayObject {
			var data:BitmapData = new BitmapData(30, 10, true, 0x00000000);
			data.fillRect(new Rectangle(0, 0, 10, 10), 0xFF00FF00);
			data.fillRect(new Rectangle(10, 0, 10, 10), 0x80FF0000);
			return new Bitmap(data);
		}

		private function shapeSource():DisplayObject {
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0x00FF00, 1);
			shape.graphics.drawRect(0, 0, 10, 10);
			shape.graphics.beginFill(0xFF0000, 0.5);
			shape.graphics.drawRect(10, 0, 10, 10);
			shape.graphics.beginFill(0x0000FF, 0);
			shape.graphics.drawRect(20, 0, 10, 10);
			shape.graphics.endFill();
			return shape;
		}

		// A linear gradient from alpha 0 to alpha 1 over [20,30), padded
		// before and after, filling [0,40): [0,20) is gradient with alpha 0.
		private function gradientSource():DisplayObject {
			var shape:Shape = new Shape();
			var box:Matrix = new Matrix();
			box.createGradientBox(10, 10, 0, 20, 0);
			shape.graphics.beginGradientFill(GradientType.LINEAR, [0xFF0000, 0xFF0000], [0, 1], [0, 255], box);
			shape.graphics.drawRect(0, 0, 40, 10);
			shape.graphics.endFill();
			return shape;
		}

		private function drawOnto(source:DisplayObject, clip:Rectangle = null):BitmapData {
			var target:BitmapData = new BitmapData(40, 10, true, 0xFF3366CC);
			target.draw(source, null, null, BlendMode.ALPHA, clip);
			return target;
		}

		// A LAYER container with an opaque background and `source` in ALPHA,
		// shown on the stage at row `y` and snapshotted with draw().
		private function layerSnapshot(source:DisplayObject, y:int):BitmapData {
			var layer:Sprite = new Sprite();
			layer.blendMode = BlendMode.LAYER;
			layer.graphics.beginFill(0x3366CC, 1);
			layer.graphics.drawRect(0, 0, 40, 10);
			layer.graphics.endFill();
			source.blendMode = BlendMode.ALPHA;
			layer.addChild(source);
			layer.y = 40 + y;
			addChild(layer);

			var snapshot:BitmapData = new BitmapData(40, 10, true, 0x00000000);
			snapshot.draw(layer);
			return snapshot;
		}

		private function probe(name:String, data:BitmapData, probes:Array):void {
			var out:Array = [];
			for each (var px:int in probes) {
				out.push(px + "=" + data.getPixel32(px, 5).toString(16));
			}
			trace(name + ": " + out.join(" "));
		}
	}
}
