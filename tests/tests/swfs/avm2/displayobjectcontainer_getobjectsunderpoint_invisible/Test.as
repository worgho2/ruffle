package {
    import flash.display.*;
    import flash.geom.*;

    // getObjectsUnderPoint and hitTestPoint over an invisible container whose
    // children are visible: tab panels that share one origin, the last one
    // added on top, the hidden ones only set to visible = false.
    [SWF(width="100", height="100")]
    public class Test extends MovieClip {
        public function Test() {
            // this -> below -> belowCell (visible panel, added first)
            var below:Sprite = box("below", false);
            addChild(below);
            below.addChild(box("belowCell", true));

            // this -> hidden -> hiddenCell, hidden -> hiddenInner -> hiddenDeep
            // (invisible panel on top; its own graphics too)
            var hidden:Sprite = box("hidden", true);
            addChild(hidden);
            hidden.addChild(box("hiddenCell", true));
            var inner:Sprite = box("hiddenInner", false);
            hidden.addChild(inner);
            var deep:Sprite = box("hiddenDeep", true);
            inner.addChild(deep);
            hidden.visible = false;

            // this -> shown -> hiddenLeaf (invisible leaf inside a visible container)
            var shown:Sprite = box("shown", false);
            addChild(shown);
            var leaf:Sprite = box("hiddenLeaf", true);
            shown.addChild(leaf);
            leaf.visible = false;

            var p:Point = new Point(5, 5);
            trace("stage.getObjectsUnderPoint: " + names(stage.getObjectsUnderPoint(p)));
            trace("root.getObjectsUnderPoint: " + names(getObjectsUnderPoint(p)));
            trace("hidden.getObjectsUnderPoint: " + names(hidden.getObjectsUnderPoint(p)));
            trace("inner.getObjectsUnderPoint: " + names(inner.getObjectsUnderPoint(p)));
            trace("shown.getObjectsUnderPoint: " + names(shown.getObjectsUnderPoint(p)));

            for each (var o:DisplayObject in [hidden, hidden.getChildAt(0), inner, deep, leaf]) {
                trace(o.name + ".hitTestPoint shape=" + o.hitTestPoint(5, 5, true)
                    + " bounds=" + o.hitTestPoint(5, 5, false));
            }

            hidden.visible = true;
            trace("hidden visible again: " + names(stage.getObjectsUnderPoint(p)));
            inner.visible = false;
            trace("inner invisible: " + names(stage.getObjectsUnderPoint(p)));
            inner.visible = true;
            visible = false;
            trace("root invisible: " + names(stage.getObjectsUnderPoint(p)));
            trace("root invisible, root.getObjectsUnderPoint: " + names(getObjectsUnderPoint(p)));
        }

        private static function box(name:String, fill:Boolean):Sprite {
            var s:Sprite = new Sprite();
            s.name = name;
            if (fill) {
                s.graphics.beginFill(0xFF0000);
                s.graphics.drawRect(0, 0, 20, 20);
                s.graphics.endFill();
            }
            return s;
        }

        private static function names(list:Array):String {
            var out:Array = [];
            for each (var o:DisplayObject in list) {
                out.push(o.name);
            }
            return "[" + out.join(",") + "]";
        }
    }
}
