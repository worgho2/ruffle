package {
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	// The advance of a tab counts in textWidth (and in the autoSize width), at
	// the start, in the middle and at the end of a line. A chat banner scrolls
	// "\t" x 32 + message + "\t" x 34 only while its textWidth is wider than
	// its 875 px window. Tab stop positions differ between players, so this
	// compares widths instead of printing them.
	public class Test extends MovieClip {
		function Test() {
			var t32:String = rep("\t", 32), t34:String = rep("\t", 34);
			var msg:String = "[janela2] aee";
			for each (var size:int in [12, 14]) {
				var m:Number = w(msg, size);
				trace("size " + size);
				trace("tab only wider than empty: " + (w("\t", size) > w("", size)));
				trace("tab+msg wider than msg: " + (w("\t" + msg, size) > m));
				trace("2tabs+msg wider than tab+msg: " + (w("\t\t" + msg, size) > w("\t" + msg, size)));
				trace("msg+tab wider than msg: " + (w(msg + "\t", size) > m));
				trace("a+tab+b wider than ab: " + (w("a\tb", size) > w("ab", size)));
				trace("32tabs+msg wider than 875: " + (w(t32 + msg, size) > 875));
				trace("msg+34tabs wider than 875: " + (w(msg + t34, size) > 875));
				trace("32tabs+msg+34tabs wider than 32tabs+msg: " + (w(t32 + msg + t34, size) > w(t32 + msg, size)));
				trace("autoSize width is textWidth + 4: " + (field(t32 + msg, size).width == field(t32 + msg, size).textWidth + 4));
			}
		}

		private static function field(text:String, size:int):TextField {
			var tf:TextField = new TextField();
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.defaultTextFormat = new TextFormat("_sans", size);
			tf.text = text;
			return tf;
		}

		private static function w(text:String, size:int):Number {
			return field(text, size).textWidth;
		}

		private static function rep(s:String, n:int):String {
			var r:String = "";
			for (var i:int = 0; i < n; i++) r += s;
			return r;
		}
	}
}
