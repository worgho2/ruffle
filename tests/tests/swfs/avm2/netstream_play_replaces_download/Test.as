package {
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.net.NetConnection;
    import flash.net.NetStream;

    public class Test extends Sprite {
        private var ns:NetStream;
        private var frames:int = 0;

        public function Test() {
            var nc:NetConnection = new NetConnection();
            nc.connect(null);

            ns = new NetStream(nc);
            ns.client = {
                onMetaData: function(info:Object):void {
                    trace("onMetaData duration: " + info.duration);
                }
            };

            // The second `play` replaces the first file before it has been
            // downloaded: none of its data may end up in the stream.
            trace("Playing first.flv, then second.flv");
            ns.play("first.flv");
            ns.play("second.flv");

            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        private function onEnterFrame(event:Event):void {
            frames++;
            if (frames == 10) {
                trace("bytesLoaded: " + ns.bytesLoaded);
                trace("bytesTotal: " + ns.bytesTotal);
                removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            }
        }
    }
}
