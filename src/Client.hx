import dn.Process;
import hxd.Key;

class Client extends Process {
	public static var ME : Client;
	public static var BG_COLOR = Color.hexToInt("#151c2d");
	public static var ALL_COLORS = [
		Color.hexToInt("#ffcc00"),
	];

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var fx : Fx;
	public var hud : ui.Hud;
	var touchCatcher : h2d.Interactive;
	var mouse : h2d.col.Point;
	var debugTf : h2d.Text;

	var drawing = false;
	var firstStroke = false;
	var color : UInt;
	var brushSize = 10;

	var lines : Array<Line> = [];
	var lastMouse : h2d.col.Point;
	var elapsedDist = 0.;

	var bg : h2d.Graphics;
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
		color = ALL_COLORS[0];

		// Init misc classes
		fx = new Fx();
		hud = new ui.Hud();

		// Init canvas
		bg = new h2d.Graphics(root);
		canvas = new h2d.Graphics(root);
		bufferCanvas = new h2d.Graphics(root);
		debugCanvas = new h2d.Graphics(root);
		debugCanvas.visible = false;

		// Init touch interactive
		lastMouse = new h2d.col.Point();
		touchCatcher = new h2d.Interactive(100,100, root);
		touchCatcher.propagateEvents = true;
		touchCatcher.onPush = function(e:hxd.Event) {
			mouse.set(e.relX*Const.SCALE, e.relY*Const.SCALE);
			startDrawing();
		}
		touchCatcher.onRelease = function(_) stopDrawing();
		touchCatcher.onReleaseOutside = function(_) stopDrawing();
		touchCatcher.onOut = function(_) stopDrawing();
		touchCatcher.onMove = onMouseMove;

		debugTf = new h2d.Text(Assets.fontSmall, root);
		debugTf.setScale(2);
	}

	function onMouseMove(e:hxd.Event) {
		mouse.set(e.relX*Const.SCALE, e.relY*Const.SCALE);
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

		// HACK: fix Graphics cropped render bug
		canvas.beginFill(0x0,0);
		canvas.drawRect(-1,-1,1,1);
		canvas.drawRect(w(),h(),1,1);
		canvas.endFill();
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
			canvas.moveTo( from.getSubX(curveDist), from.getSubY(curveDist) );
			canvas.lineTo( from.getSubX(1-curveDist+0.1), from.getSubY(1-curveDist+0.1) );
			canvas.curveTo(
				from.tx,
				from.ty,
				to.getSubX(curveDist),
				to.getSubY(curveDist)
			);

			bufferCanvas.clear();
			bufferCanvas.lineStyle(brushSize, 0x00ff00);
			bufferCanvas.moveTo( to.getSubX(1-curveDist), to.getSubY(1-curveDist) );
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

		bg.clear();
		bg.beginFill(BG_COLOR);
		bg.drawRect(0,0,w(),h());

		touchCatcher.width = w();
		touchCatcher.height = h();
	}

	override function onDispose() {
		super.onDispose();

		fx.destroy();
	}

	override function preUpdate() {
		super.preUpdate();
	}

	override function postUpdate() {
		super.postUpdate();
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

		#if debug
		debugTf.text = Std.string( M.round(hxd.Timer.fps()) );
		#end
	}
}

