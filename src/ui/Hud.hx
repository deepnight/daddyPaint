package ui;

class Hud extends dn.Process {
	public var client(get,never) : Client; inline function get_client() return Client.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Client.ME.fx;

	var flow : h2d.Flow;
	var invalidated = true;

	public function new() {
		super(Client.ME);

		createRootInLayers(client.root, Const.DP_UI);

		flow = new h2d.Flow(root);
	}

	override function onDispose() {
		super.onDispose();
	}

	public inline function invalidate() invalidated = true;

	function render() {}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}
