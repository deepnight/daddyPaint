import dn.Process;
import hxd.Key;

class Client extends Process {
	public static var ME : Client;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var fx : Fx;
	public var hud : ui.Hud;
	var touchCatcher : h2d.Interactive;
	var mouse : h2d.col.Point;
	var debugTf : h2d.Text;

	var touchDrawingData : Map<Int, TouchDrawingData> = new Map();
	var color : UInt;
	var brushSize = 10;

	var lines : Array<Line> = [];

	var bg : h2d.Graphics;
	var canvas : h2d.Graphics;
	var debugCanvas : h2d.Graphics;

	var skipFrames = 0.; // TODO

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("client");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);
		createRootInLayers(Main.ME.root, Const.DP_BG);
		mouse = new h2d.col.Point();
		color = Const.ALL_COLORS[0];

		// Init misc classes
		fx = new Fx();
		hud = new ui.Hud();

		// Init canvas
		bg = new h2d.Graphics(root);
		canvas = new h2d.Graphics(root);
		debugCanvas = new h2d.Graphics(root);
		debugCanvas.visible = false;

		// Init touch interactive
		touchCatcher = new h2d.Interactive(100,100, root);
		touchCatcher.propagateEvents = true;
		touchCatcher.onPush = function(e) startDrawing(e);
		touchCatcher.onRelease = function(e) stopDrawing(e);
		touchCatcher.onReleaseOutside = function(e) stopDrawing(e);
		touchCatcher.onOut = function(e) stopDrawing(e);
		touchCatcher.onMove = onMouseMove;

		debugTf = new h2d.Text(Assets.fontSmall, root);
		debugTf.setScale(2);
	}

	function onMouseMove(e:hxd.Event) {
		if( !touchDrawingData.exists(e.touchId) )
			return;

		var tdata = touchDrawingData.get(e.touchId);

		#if debug
		if( skipFrames>0 && cd.hasSetS("skipFrame",skipFrames) )
			return;
		#end

		var mx = e.relX;
		var my = e.relY;
		if( mx!=tdata.mouseX || my!=tdata.mouseY ) {
			var radius = brushSize*0.5;

			// Debug render
			#if debug
			debugCanvas.lineStyle(3, 0xff0000);
			debugCanvas.moveTo(tdata.mouseX, tdata.mouseY);
			debugCanvas.lineTo(mx, my);
			#end

			// Smoothing
			var l = new data.Line(tdata.mouseX, tdata.mouseY, mx, my, color);
			tdata.bufferLines.push(l);
			lines.push(l);
			flushLineBuffer(e, false);
		}

		tdata.updateMouseCoords(e);
	}

	inline function getGlobalMouseX() return mouse.x;
	inline function getGlobalMouseY() return mouse.y;

	inline function getClientMouseX() return Std.int( getGlobalMouseX() / Const.SCALE );
	inline function getClientMouseY() return Std.int( getGlobalMouseY() / Const.SCALE );

	function clear() {
		for(d in touchDrawingData)
			d.dispose();
		touchDrawingData = new Map();

		canvas.clear();
		debugCanvas.clear();
		lines = [];
	}

	function startDrawing(e:hxd.Event) {
		if( touchDrawingData.exists(e.touchId) )
			return;


		var tdata = new TouchDrawingData(e);
		touchDrawingData.set(tdata.touchId, tdata);
		fx.smokeTap(tdata.mouseX, tdata.mouseY, color);

		// Debug: start mark
		#if debug
		debugCanvas.beginFill(0x0);
		debugCanvas.lineStyle(3,0xff0000);
		debugCanvas.drawCircle(tdata.mouseX, tdata.mouseY, 15);
		debugCanvas.beginFill(0xff0000);
		debugCanvas.drawCircle(tdata.mouseX, tdata.mouseY, 5);
		#end

		// Line rounded start
		canvas.lineStyle();
		canvas.beginFill(color);
		canvas.drawCircle(tdata.mouseX, tdata.mouseY, brushSize*0.4);
		canvas.endFill();
	}

	function stopDrawing(e:hxd.Event) {
		if( !touchDrawingData.exists(e.touchId) )
			return;

		var tdata = touchDrawingData.get(e.touchId);
		flushLineBuffer(e, true);

		// Line rounded end
		canvas.lineStyle();
		canvas.beginFill(color);
		canvas.drawCircle(tdata.mouseX, tdata.mouseY, brushSize*0.4);
		canvas.endFill();

		// HACK: fix cropped h2d.Graphics render bug
		canvas.lineStyle();
		canvas.beginFill(0x0,0);
		canvas.drawRect(-1,-1,1,1);
		canvas.drawRect(w(),h(),1,1);
		canvas.endFill();

		touchDrawingData.remove(tdata.touchId);
		tdata.dispose();
	}

	function flushLineBuffer(e:hxd.Event, isFinal:Bool) {
		var tdata = touchDrawingData.get(e.touchId);

		var curveDist = 0.4;
		canvas.lineStyle(brushSize, color);

		if( tdata.firstStroke && tdata.bufferLines.length>0 ) {
			var l = tdata.bufferLines[0];
			canvas.moveTo(l.fx, l.fy);
			canvas.lineTo(l.getSubX(1-curveDist), l.getSubY(1-curveDist));
			tdata.firstStroke = false;
		}

		// Render while easing corners
		while( tdata.bufferLines.length>=2 ) {
			var from = tdata.bufferLines.shift();
			var to = tdata.bufferLines[0];
			tdata.avgDist = 0.9*tdata.avgDist + 0.1*from.length;

			canvas.moveTo( from.getSubX(curveDist), from.getSubY(curveDist) );
			canvas.lineTo( from.getSubX(1-curveDist+0.1), from.getSubY(1-curveDist+0.1) );
			canvas.curveTo(
				from.tx,
				from.ty,
				to.getSubX(curveDist),
				to.getSubY(curveDist)
			);

			tdata.bufferCanvas.clear();
			tdata.bufferCanvas.lineStyle(brushSize, 0xffffff);
			tdata.bufferCanvas.moveTo( to.getSubX(1-curveDist), to.getSubY(1-curveDist) );
			tdata.bufferCanvas.lineTo(to.tx, to.ty);
		}

		// Debug: segment end
		#if debug
		debugCanvas.lineStyle();
		debugCanvas.beginFill(0xff0000);
		debugCanvas.drawCircle(tdata.mouseX, tdata.mouseY, 5);
		#end

		// Final segment
		if( isFinal && tdata.bufferLines.length>0 ) {
			var last = tdata.bufferLines[0];
			canvas.lineStyle(brushSize, color);
			canvas.moveTo(
				last.fx+Math.cos(last.angle)*last.length*curveDist,
				last.fy+Math.sin(last.angle)*last.length*curveDist
			);
			canvas.lineTo(last.tx, last.ty);
			tdata.bufferCanvas.clear();
			tdata.bufferLines = [];
		}
	}

	override function onResize() {
		super.onResize();

		bg.clear();
		bg.beginFill(Const.BG_COLOR);
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
		var t = "";
		for(d in touchDrawingData)
			t += "#"+d.touchId+"(avg="+Std.int(d.avgDist)+") ";
		debugTf.text = M.round(hxd.Timer.fps()) + " touches="+t;
		#end
	}
}

