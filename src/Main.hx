import Data;
import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;
	public var controller : dn.heaps.Controller;
	public var ca : dn.heaps.Controller.ControllerAccess;

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
		#if debug
		hxd.Res.initLocal();
        #else
        hxd.Res.initEmbed();
        #end

        // Hot reloading
		#if debug
        hxd.res.Resource.LIVE_UPDATE = true;
        hxd.Res.data.watch(function() {
            delayer.cancelById("cdb");

            delayer.addS("cdb", function() {
            	Data.load( hxd.Res.data.entry.getBytes().toString() );
            	if( Client.ME!=null )
                    Client.ME.onCdbReload();
            }, 0.2);
        });
		#end

		// Assets & data init
		Lang.init("en");
		Assets.init();
		Data.load( hxd.Res.data.entry.getText() );

		// Console
		new ui.Console(Assets.fontTiny, s);

		// Game controller
		controller = new dn.heaps.Controller(s);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.Q, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(X, Key.SPACE, Key.F, Key.E);
		controller.bind(A, Key.UP, Key.Z, Key.W);
		controller.bind(B, Key.ENTER, Key.NUMPAD_ENTER);
		controller.bind(SELECT, Key.R);
		controller.bind(START, Key.N);

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
		dn.heaps.slib.SpriteLib.TMOD = tmod;
        super.update();
    }
}