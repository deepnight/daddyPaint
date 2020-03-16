package data;

class Line {
	public var fx : Int;
	public var fy : Int;
	public var tx : Int;
	public var ty : Int;
	public var color : UInt;

	public var angle(get,never) : Float; inline function get_angle() return Math.atan2(ty-fy, tx-fx);
	public var length(get,never) : Float; inline function get_length() return M.dist(fx,fy, tx,ty);

	public function new(fx:Float, fy:Float, tx:Float, ty:Float, c:UInt) {
		this.fx = Std.int(fx);
		this.fy = Std.int(fy);

		this.tx = Std.int(tx);
		this.ty = Std.int(ty);

		this.color = c;
	}

	public inline function getSubX(ratio:Float) {
		return fx + Math.cos(angle) * length * ratio;
	}

	public inline function getSubY(ratio:Float) {
		return fy + Math.sin(angle) * length * ratio;
	}
}