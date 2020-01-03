import dn.Process;
import hxd.Key;

class Client extends Process {
	public static var ME : Client;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var fx : Fx;
	public var hud : ui.Hud;

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("client");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);
		createRootInLayers(Main.ME.root, Const.DP_BG);

		fx = new Fx();
		hud = new ui.Hud();
	}

	public function onCdbReload() {
	}


	function gc() {
	}

	override function onDispose() {
		super.onDispose();

		fx.destroy();
		gc();
	}

	override function update() {
		super.update();

		// Updates
		gc();

		if( !ui.Console.ME.isActive() && !ui.Modal.hasAny() ) {
			#if hl
			// Exit
			if( ca.isKeyboardPressed(Key.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					trace(Lang.t._("Press ESCAPE again to exit."));
				else
					hxd.System.exit();
			#end

			// Restart
			if( ca.selectPressed() )
				Main.ME.startClient();
		}
	}
}

