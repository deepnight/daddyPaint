import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;

	public function new(s:h2d.Scene) {
		super();
		ME = this;

        createRoot(s);
        root.filter = new h2d.filter.ColorMatrix(); // force rendering for pixel perfect

		// Engine settings
		hxd.Timer.wantedFPS = Const.FPS;
		engine.backgroundColor = 0xff<<24|0x111133;
        // #if( hl && !debug )
        engine.fullScreen = true;
        // #end

		// Resources
		#if(hl && debug)
		hxd.Res.initLocal();
        #else
        hxd.Res.initEmbed();
        #end

		// Assets & data init
		Lang.init("en");
		Assets.init();

		// Console
		new ui.Console(Assets.fontTiny, s);

		// Start
		startClient();
	}

	public function startClient() {
		if( Client.ME!=null ) {
			Client.ME.destroy();
			delayer.addF(function() {
				new Client();
				dn.Process.resizeAll();
			}, 1);
		}
		else {
			new Client();
			dn.Process.resizeAll();
		}
	}

	override public function onResize() {
		super.onResize();

		// Auto scaling
		if( Const.AUTO_SCALE_TARGET_WID>0 )
			Const.SCALE = M.ceil( h()/Const.AUTO_SCALE_TARGET_WID );
		else if( Const.AUTO_SCALE_TARGET_HEI>0 )
			Const.SCALE = M.ceil( h()/Const.AUTO_SCALE_TARGET_HEI );
		root.setScale(Const.SCALE);
	}

    override function update() {
		Assets.tiles.tmod = tmod;
        super.update();
    }
}