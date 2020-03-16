import dn.Process;
import hxd.Key;

class Client extends Process {
	public static var ME : Client;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var fx : Fx;
	public var hud : ui.Hud;

	var drawing = false;
	var color : UInt = 0xffffff;
	// public var canvas : hxd.Pixels;
	var lines : Array<Line> = [];
	var lastPoint : h2d.col.Point;
	var canvas : h2d.Graphics;

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("client");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);
		createRootInLayers(Main.ME.root, Const.DP_BG);

		fx = new Fx();
		hud = new ui.Hud();
		lastPoint = new h2d.col.Point();
		canvas = new h2d.Graphics(root);

		Boot.ME.s2d.addEventListener( onEvent );
	}

	function onEvent(e:hxd.Event) {
		switch e.kind {
			case EPush:
				startDrawing();

			case ERelease, EReleaseOutside, EFocusLost:
				stopDrawing();

			case EMove:
			case EOver:
			case EOut:
			case EWheel:
			case EFocus:
			case EKeyDown:
			case EKeyUp:
			case ETextInput:
			case ECheck:
		}
	}

	inline function getGlobalMouseX() return Boot.ME.s2d.mouseX;
	inline function getGlobalMouseY() return Boot.ME.s2d.mouseY;

	inline function getClientMouseX() return Std.int( getGlobalMouseX() / Const.SCALE );
	inline function getClientMouseY() return Std.int( getGlobalMouseY() / Const.SCALE );

	function startDrawing() {
		drawing = true;
		lastPoint.set( getClientMouseX(), getClientMouseY() );
	}
	function stopDrawing() {
		drawing = false;
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

	override function preUpdate() {
		super.preUpdate();
	}

	override function postUpdate() {
		super.postUpdate();
		gc();
	}

	override function update() {
		super.update();

		if( drawing ) {
			var mx = getClientMouseX();
			var my = getClientMouseY();
			if( mx!=lastPoint.x || my!=lastPoint.y ) {
				canvas.lineStyle(8,color);
				canvas.moveTo(lastPoint.x, lastPoint.y);
				canvas.lineTo(mx,my);

				lines.push( new data.Line(lastPoint.x, lastPoint.y, mx, my, color) );
				lastPoint.set(mx,my);
			}
		}

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

