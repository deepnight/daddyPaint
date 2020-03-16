import dn.Process;
import hxd.Key;

class Client extends Process {
	public static var ME : Client;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var fx : Fx;
	public var hud : ui.Hud;
	var touchCatcher : h2d.Interactive;
	var mouse : h2d.col.Point;

	var drawing = false;
	var firstStroke = false;
	var color : UInt = 0xffffff;
	var brushSize = 10;

	var lines : Array<Line> = [];
	var lastMouse : h2d.col.Point;
	var elapsedDist = 0.;

	var canvas : h2d.Graphics;
	var debugCanvas : h2d.Graphics;

	var bufferCanvas : h2d.Graphics;
	var bufferLines : Array<Line> = [];
	var skipFrames = 0.;

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("client");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);
		createRootInLayers(Main.ME.root, Const.DP_BG);
		mouse = new h2d.col.Point();

		// Init misc classes
		fx = new Fx();
		hud = new ui.Hud();

		// Init touch interactive
		lastMouse = new h2d.col.Point();
		touchCatcher = new h2d.Interactive(100,100, root);
		touchCatcher.propagateEvents = true;
		touchCatcher.onPush = function(e:hxd.Event) {
			mouse.set(e.relX, e.relY);
			startDrawing();
		}
		touchCatcher.onRelease = function(_) stopDrawing();
		touchCatcher.onReleaseOutside = function(_) stopDrawing();
		touchCatcher.onOut = function(_) stopDrawing();
		touchCatcher.onMove = onMouseMove;

		// Init canvas
		canvas = new h2d.Graphics(root);
		bufferCanvas = new h2d.Graphics(root);
		debugCanvas = new h2d.Graphics(root);
		debugCanvas.visible = false;

		// Boot.ME.s2d.addEventListener( onEvent );
	}

	// function onEvent(e:hxd.Event) {
	// 	switch e.kind {
	// 		case EPush:
	// 			startDrawing();

	// 		case ERelease, EReleaseOutside, EFocusLost:
	// 			stopDrawing();

	// 		case EMove:
	// 		case EOver:
	// 		case EOut:
	// 		case EWheel:
	// 		case EFocus:
	// 		case EKeyDown:
	// 		case EKeyUp:
	// 		case ETextInput:
	// 		case ECheck:
	// 	}
	// }

	function onMouseMove(e:hxd.Event) {
		mouse.set(e.relX, e.relY);
		if( drawing #if debug && !cd.hasSetS("skipFrame",skipFrames) #end ) {
			var mx = getClientMouseX();
			var my = getClientMouseY();
			if( mx!=lastMouse.x || my!=lastMouse.y ) {
				var radius = brushSize*0.5;

				// Debug render
				#if debug
				debugCanvas.lineStyle(3, 0xff0000);
				debugCanvas.moveTo(lastMouse.x, lastMouse.y);
				debugCanvas.lineTo(mx, my);
				#end

				// Smoothing
				var l = new data.Line(lastMouse.x, lastMouse.y, mx, my, color);
				bufferLines.push(l);
				lines.push(l);
				flushLineBuffer(false);

				lastMouse.set(mx,my);
			}
		}
	}

	inline function getGlobalMouseX() return mouse.x;
	inline function getGlobalMouseY() return mouse.y;
	// inline function getGlobalMouseX() return Boot.ME.s2d.mouseX;
	// inline function getGlobalMouseY() return Boot.ME.s2d.mouseY;

	inline function getClientMouseX() return Std.int( getGlobalMouseX() / Const.SCALE );
	inline function getClientMouseY() return Std.int( getGlobalMouseY() / Const.SCALE );

	function clear() {
		stopDrawing();
		canvas.clear();
		bufferCanvas.clear();
		debugCanvas.clear();
		lines = [];
		bufferLines = [];
	}

	function startDrawing() {
		#if debug
		debugCanvas.beginFill(0x0);
		debugCanvas.lineStyle(3,0xff0000);
		debugCanvas.drawCircle(getClientMouseX(), getClientMouseY(), 15);
		debugCanvas.beginFill(0xff0000);
		debugCanvas.drawCircle(getClientMouseX(), getClientMouseY(), 5);
		#end

		drawing = true;
		firstStroke = true;
		lastMouse.set( getClientMouseX(), getClientMouseY() );
		elapsedDist = 0;
	}

	function stopDrawing() {
		drawing = false;
		firstStroke = false;
		flushLineBuffer(true);
	}

	function flushLineBuffer(all:Bool) {
		var curveDist = 0.4;
		canvas.lineStyle(brushSize, color);

		if( firstStroke && bufferLines.length>0 ) {
			var l = bufferLines[0];
			canvas.moveTo(l.fx, l.fy);
			canvas.lineTo(l.getSubX(1-curveDist), l.getSubY(1-curveDist));
			firstStroke = false;
		}

		// Render while easing corners
		while( bufferLines.length>=2 ) {
			var from = bufferLines.shift();
			var to = bufferLines[0];
			canvas.moveTo(
				from.fx+Math.cos(from.angle)*from.length*curveDist,
				from.fy+Math.sin(from.angle)*from.length*curveDist
			);
			canvas.lineTo(
				from.fx+Math.cos(from.angle)*from.length*(1-curveDist),
				from.fy+Math.sin(from.angle)*from.length*(1-curveDist)
			);
			canvas.curveTo(
				from.tx,
				from.ty,
				to.fx+Math.cos(to.angle)*to.length*curveDist,
				to.fy+Math.sin(to.angle)*to.length*curveDist
			);

			bufferCanvas.clear();
			bufferCanvas.lineStyle(brushSize, 0x00ff00);
			bufferCanvas.moveTo(
				to.fx+Math.cos(to.angle)*to.length*(1-curveDist),
				to.fy+Math.sin(to.angle)*to.length*(1-curveDist)
			);
			bufferCanvas.lineTo(to.tx, to.ty);
		}

		// Final segment
		if( all && bufferLines.length>0 ) {
			var last = bufferLines[0];
			canvas.lineStyle(brushSize, color);
			canvas.moveTo(
				last.fx+Math.cos(last.angle)*last.length*curveDist,
				last.fy+Math.sin(last.angle)*last.length*curveDist
			);
			canvas.lineTo(last.tx, last.ty);
			bufferCanvas.clear();
			bufferLines = [];
		}
	}

	override function onResize() {
		super.onResize();
		touchCatcher.width = w();
		touchCatcher.height = h();
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

		if( !ui.Console.ME.isActive() && !ui.Modal.hasAny() ) {
			// Clear canvas
			if( hxd.Key.isPressed(Key.C) )
				clear();

			// Show debug lines
			#if debug
			if( hxd.Key.isPressed(Key.D) ) {
				debugCanvas.visible = !debugCanvas.visible;
				canvas.alpha = debugCanvas.visible ? 0.3 : 1;
				touchCatcher.backgroundColor = debugCanvas.visible ? Color.addAlphaF(0x00ff00,0.2) : 0x0;
			}
			#end

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

