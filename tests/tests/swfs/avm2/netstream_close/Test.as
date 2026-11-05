package {
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.NetStatusEvent;
    import flash.net.NetConnection;
    import flash.net.NetStream;

    public class Test extends Sprite {
        private var ns:NetStream;
        private var phase:String = "first play";
        private var wait:int = -1;

        public function Test() {
            var nc:NetConnection = new NetConnection();
            nc.connect(null);
            ns = new NetStream(nc);
            ns.client = {
                onMetaData: function(info:Object):void {}
            };
            ns.addEventListener(NetStatusEvent.NET_STATUS, onStatus);

            phase = "close before play";
            ns.close();
            dump("after close before play");

            phase = "first play";
            trace("play");
            ns.play("test.flv");
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        private function dump(label:String):void {
            trace(label + ": time", ns.time, "bytesLoaded", ns.bytesLoaded, "bytesTotal", ns.bytesTotal);
        }

        private function onStatus(event:NetStatusEvent):void {
            // Flash sends Buffer.Flush, Play.Stop and Buffer.Empty of the first
            // play when the data ends, Ruffle when playback ends: only the
            // events from the first close on are traced.
            if (phase == "first play") {
                if (event.info.code == "NetStream.Buffer.Full" && wait < 0) {
                    wait = 6;
                }
                return;
            }
            trace("[" + phase + "] " + event.info.code);
        }

        private function onFrame(event:Event):void {
            if (wait < 0 || --wait > 0) {
                return;
            }
            wait = -1;
            if (phase == "first play") {
                trace("playing before close:", ns.time > 0);
                phase = "closing";
                ns.close();
                dump("after close");
                // Two seconds at 24 fps, past the end of the 1.07 s file.
                phase = "after close";
                wait = 48;
            } else if (phase == "after close") {
                dump("two seconds later");
                phase = "closing again";
                ns.close();
                trace("second close: ok");
                phase = "replay";
                ns.play("test.flv");
            }
        }
    }
}
