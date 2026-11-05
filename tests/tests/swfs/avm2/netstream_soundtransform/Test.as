package {
    import flash.display.Sprite;
    import flash.media.SoundTransform;
    import flash.net.NetConnection;
    import flash.net.NetStream;

    public class Test extends Sprite {
        public function Test() {
            var nc:NetConnection = new NetConnection();
            nc.connect(null);
            var ns:NetStream = new NetStream(nc);

            dump("default", ns.soundTransform);

            ns.soundTransform = new SoundTransform(0.25, -0.5);
            dump("set 0.25 -0.5", ns.soundTransform);

            var copy:SoundTransform = ns.soundTransform;
            copy.volume = 0.9;
            dump("after editing the returned object", ns.soundTransform);
            trace("same object twice:", ns.soundTransform === ns.soundTransform);

            ns.soundTransform = new SoundTransform(0);
            dump("set 0", ns.soundTransform);

            ns.soundTransform = new SoundTransform(0.5);
            dump("set 0.5", ns.soundTransform);

            try {
                ns.soundTransform = null;
                trace("set null: accepted");
            } catch (e:Error) {
                trace("set null:", e.errorID);
            }
            dump("after null", ns.soundTransform);
        }

        private function dump(label:String, st:SoundTransform):void {
            trace(label + ":", st.volume, st.pan, st.leftToLeft, st.leftToRight,
                st.rightToLeft, st.rightToRight);
        }
    }
}
