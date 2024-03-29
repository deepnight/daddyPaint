import dn.Process;
import hxd.Key;

class Client extends Process {
	public static var ME : Client;

	public var fx : Fx;
	public var hud : ui.Hud;
	var touchCatcher : h2d.Interactive;
	var mouse : h2d.col.Point;
	var debugTf : h2d.Text;

	var touchDrawingData : Map<Int, TouchDrawingData> = new Map();
	public var color : UInt;
	public var baseBrushSize = 10;

	var lines : Array<Line> = [];

	var wrapper : h2d.Object;
	var bg : h2d.Graphics;
	var flatten : Null<h2d.Bitmap>;
	var canvas : h2d.Graphics;
	var debugCanvas : h2d.Graphics;

	var skipFrames = 0.; // TODO
	public var theme : Theme;

	public function new() {
		super(Main.ME);
		ME = this;
		createRootInLayers(Main.ME.root, Const.DP_BG);
		mouse = new h2d.col.Point();
		theme = Const.THEMES[1];
		color = theme.palette[0];

		// Init misc classes
		fx = new Fx();
		hud = new ui.Hud();

		// Init canvas
		bg = new h2d.Graphics();
		root.add(bg, Const.DP_BG);

		wrapper = new h2d.Object();
		root.add(wrapper, Const.DP_MAIN);
		canvas = new h2d.Graphics(wrapper);

		debugCanvas = new h2d.Graphics();
		root.add(debugCanvas, Const.DP_MAIN);
		debugCanvas.visible = false;

		// Init touch interactive
		touchCatcher = new h2d.Interactive(100,100);
		root.add(touchCatcher, Const.DP_MAIN);
		touchCatcher.propagateEvents = true;
		touchCatcher.onPush = function(e) startDrawing(e);
		touchCatcher.onRelease = function(e) stopDrawing(e);
		touchCatcher.onReleaseOutside = function(e) stopDrawing(e);
		touchCatcher.onOut = function(e) stopDrawing(e);
		touchCatcher.onMove = onMouseMove;

		debugTf = new h2d.Text(Assets.fontSmall);
		root.add(debugTf, Const.DP_TOP);
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
			var radius = tdata.getBrushSize()*0.5;

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
		disposeFlatten();

		canvas.clear();
		debugCanvas.clear();
		lines = [];
	}

	public inline function isEraser() return color==theme.bg;
	public function isDrawing() {
		for(d in touchDrawingData)
			return true;
		return false;
	}

	function startDrawing(e:hxd.Event) {
		if( touchDrawingData.exists(e.touchId) )
			return;


		var tdata = new TouchDrawingData(e);
		touchDrawingData.set(tdata.touchId, tdata);

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
		canvas.drawCircle(tdata.mouseX, tdata.mouseY, tdata.getBrushSize()*0.5);
		canvas.endFill();
	}

	function stopDrawing(e:hxd.Event) {
		if( !touchDrawingData.exists(e.touchId) )
			return;

		var tdata = touchDrawingData.get(e.touchId);
		flushLineBuffer(e, true);

		if( tdata.checkTap(true) )
			fx.smokeTap(tdata.mouseX, tdata.mouseY, color);

		// Line rounded end
		canvas.lineStyle();
		canvas.beginFill(color);
		canvas.drawCircle(tdata.mouseX, tdata.mouseY, tdata.getBrushSize()*0.5);
		canvas.endFill();

		// HACK: fix cropped h2d.Graphics render bug
		canvas.lineStyle();
		canvas.beginFill(0x0,0);
		canvas.drawRect(-1,-1,1,1);
		canvas.drawRect(w(),h(),1,1);
		canvas.endFill();

		touchDrawingData.remove(tdata.touchId);
		tdata.dispose();
		cd.setS("canvasFlushRequired", Const.INFINITE);
		cd.setS("canvasFlushLocked", 0.5);
	}

	function flushLineBuffer(e:hxd.Event, isFinal:Bool) {
		var curveDist = 0.4;
		var tdata = touchDrawingData.get(e.touchId);

		inline function drawSegment(fx:Float, fy:Float, tx:Float, ty:Float) {
			canvas.lineStyle(tdata.getBrushSize(), color);
			if( isEraser() )
				this.fx.eraserSegment( fx,fy, tx,ty, tdata.getBrushSize(), 0xABB9DB );
			else
				this.fx.segment( fx,fy, tx,ty, tdata.getBrushSize(), color );
			canvas.moveTo(fx,fy);
			canvas.lineTo(tx,ty);
		}

		if( tdata.firstStroke && tdata.bufferLines.length>0 ) {
			var l = tdata.bufferLines[0];
			drawSegment(
				l.fx, l.fy,
				l.getSubX(1-curveDist), l.getSubY(1-curveDist)
			);
			tdata.firstStroke = false;
		}

		// Render while easing corners
		while( tdata.bufferLines.length>=2 ) {
			var from = tdata.bufferLines.shift();
			var to = tdata.bufferLines[0];
			tdata.avgDist = 0.9*tdata.avgDist + 0.1*from.length;

			drawSegment(
				from.getSubX(curveDist), from.getSubY(curveDist),
				from.getSubX(1-curveDist+0.1), from.getSubY(1-curveDist+0.1)
			);
			canvas.curveTo(
				from.tx,
				from.ty,
				to.getSubX(curveDist),
				to.getSubY(curveDist)
			);

			tdata.bufferCanvas.clear();
			tdata.bufferCanvas.lineStyle(tdata.getBrushSize(), isEraser() ? color : 0xffffff);
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
			drawSegment(
				last.fx+Math.cos(last.angle)*last.length*curveDist, last.fy+Math.sin(last.angle)*last.length*curveDist,
				last.tx, last.ty
			);
			tdata.bufferCanvas.clear();
			tdata.bufferLines = [];
		}
	}

	override function onResize() {
		super.onResize();

		bg.clear();
		bg.beginFill(theme.bg);
		bg.drawRect(0,0,w(),h());

		touchCatcher.width = w();
		touchCatcher.height = h();
	}

	override function onDispose() {
		super.onDispose();

		fx.destroy();
	}

	function disposeFlatten() {
		if( flatten==null )
			return;

		flatten.tile.dispose();
		flatten.tile = null;
		flatten.remove();
		flatten = null;
	}

	function flushCanvasToTexture() {
		var tile = getCanvasTile();

		// Clear previous flatten bitmap
		disposeFlatten();

		// Add new flatten
		flatten = new h2d.Bitmap(tile);
		wrapper.addChildAt(flatten,0);
		flatten.setScale(1/Const.SCALE); // HACK TODO should capture in lower res
		canvas.clear();
	}

	function getCanvasTexture() {
		var t = haxe.Timer.stamp();
		var tex = new h3d.mat.Texture( w(), h(), [Target] );
		wrapper.drawTo(tex);
		// #if debug
		// trace("capture="+M.pretty(haxe.Timer.stamp()-t)+"s, "+tex.width+"x"+tex.height);
		// #end
		return tex;
	}

	function getCanvasTile() {
		return h2d.Tile.fromTexture( getCanvasTexture() );
	}

	override function preUpdate() {
		super.preUpdate();
	}

	override function postUpdate() {
		super.postUpdate();
	}

	override function update() {
		super.update();

		// for(data in touchDrawingData)
		// 	if( data.checkTap(false) )
		// 		fx.smokeTap(data.originX, data.originY, color);


		if( !ui.Console.ME.isActive() ) {
			// Clear canvas
			if( hxd.Key.isPressed(Key.C) )
				clear();

			// Toggle fullscreen
			if( hxd.Key.isPressed(Key.F) || Key.isDown(Key.ALT) && Key.isPressed(Key.ENTER) )
				engine.fullScreen = !engine.fullScreen;

			// Show debug lines
			#if debug
			if( hxd.Key.isPressed(Key.D) ) {
				debugCanvas.visible = !debugCanvas.visible;
				canvas.alpha = debugCanvas.visible ? 0.3 : 1;
				touchCatcher.backgroundColor = debugCanvas.visible ? Color.addAlphaF(0x00ff00,0.2) : 0x0;
			}
			#end

			// Flush into texture
			#if debug
			if( hxd.Key.isPressed(Key.T) ) {
				flushCanvasToTexture();
				// var bmp = new h2d.Bitmap( getCanvasTile() );
				// root.add(bmp, Const.DP_TOP);
				// bmp.scale(0.5/Const.SCALE);
			}
			#end

			#if hl
			// Exit
			if( Key.isPressed(Key.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					trace(Lang.t._("Press ESCAPE again to exit."));
				else
					hxd.System.exit();
			#end

			// Restart
			if( Key.isPressed(Key.R) )
				Main.ME.startClient();
		}

		// Flatten canvas
		if( cd.has("canvasFlushRequired") && !cd.has("canvasFlushLocked") && !isDrawing() ) {
			flushCanvasToTexture();
			cd.unset("canvasFlushRequired");
		}

		#if debug
		var t = "";
		for(d in touchDrawingData)
			t += "#"+d.touchId+"(avg="+Std.int(d.avgDist)+") ";
		debugTf.text = M.round(hxd.Timer.fps()) + "fps"
			+" fx="+fx.pool.allocated
			+" touches="+t
			+" "+isDrawing();
		#end
	}
}

