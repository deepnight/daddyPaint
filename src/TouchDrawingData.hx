class TouchDrawingData {
	var client(get,never) : Client; inline function get_client() return Client.ME;

	public var touchId : Int;
	public var firstStroke = true;
	var tapDone = false;
	public var avgDist = 0.;
	public var bufferLines : Array<Line> = [];
	public var bufferCanvas : h2d.Graphics;

	var startTime : Float;
	public var originX(default,null) : Float;
	public var originY(default,null) : Float;

	var lastKnownMouse : h2d.col.Point;

	public var mouseX(get,never) : Float; inline function get_mouseX() return Std.int(lastKnownMouse.x/Const.SCALE);
	public var mouseY(get,never) : Float; inline function get_mouseY() return Std.int(lastKnownMouse.y/Const.SCALE);

	public function new(e:hxd.Event) {
		this.touchId = e.touchId;
		bufferCanvas = new h2d.Graphics(client.root);
		startTime = haxe.Timer.stamp();
		updateMouseCoords(e);
		originX = mouseX;
		originY = mouseY;
	}

	public function getBrushSize() {
		return client.baseBrushSize * ( 0.6 + 0.4*Math.cos(getElapsedTimeS()*8) );
	}

	public inline function getElapsedTimeS() return haxe.Timer.stamp() - startTime;
	public inline function getDistToOrigin() return M.dist(originX, originY, mouseX, mouseY);

	public function checkTap(onRelease:Bool) {
		if( !tapDone && ( onRelease || getElapsedTimeS()>=0.07 ) && getDistToOrigin()<=40 ) {
			tapDone = true;
			return true;
		}
		return false;
	}

	public function updateMouseCoords(e:hxd.Event) {
		lastKnownMouse = new h2d.col.Point(e.relX*Const.SCALE, e.relY*Const.SCALE);
	}

	public function dispose() {
		bufferLines = null;
		lastKnownMouse = null;
		bufferCanvas.remove();
		bufferCanvas = null;
	}

	public function toString() return "Touch#"+touchId;
}