package data;

class Line {
	public var fx : Int;
	public var fy : Int;
	public var tx : Int;
	public var ty : Int;
	public var color : UInt;

	public function new(fx:Float, fy:Float, tx:Float, ty:Float, c:UInt) {
		this.fx = Std.int(fx);
		this.fy = Std.int(fy);

		this.tx = Std.int(tx);
		this.ty = Std.int(ty);

		this.color = c;
	}
}