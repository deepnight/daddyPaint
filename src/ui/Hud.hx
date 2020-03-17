package ui;

class Hud extends dn.Process {
	public var client(get,never) : Client; inline function get_client() return Client.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Client.ME.fx;

	var flow : h2d.Flow;
	var invalidated = true;
	var palette : h2d.Layers;

	public function new() {
		super(Client.ME);

		createRootInLayers(client.root, Const.DP_UI);

		palette = new h2d.Layers(root);
		flow = new h2d.Flow(root);
	}

	override function onDispose() {
		super.onDispose();
	}

	public inline function invalidate() invalidated = true;

	override function onResize() {
		super.onResize();
		invalidate();
	}

	function render() {
		// Palette
		palette.removeChildren();
		var chei = M.ceil( h()/Const.SCALE / Const.ALL_COLORS.length );
		var idx = 0;
		var active = null;
		for(c in Const.ALL_COLORS) {
			var i = new h2d.Interactive(w()/Const.SCALE*0.07, chei, palette);
			i.propagateEvents = true;
			i.y = chei*idx;

			if( c==client.color ) {
				active = i;
				i.width+=7;
				i.filter = new h2d.filter.Glow(0x0, 1, 64, true);
				i.backgroundColor = C.addAlphaF(c);
			}
			else
				i.backgroundColor = C.addAlphaF( C.toBlack(c,0.1) );

			i.onClick = function(_) {
				// Select color
				client.color = c;
				fx.pickColor(palette.x+i.x, palette.y+i.y, i.width, i.height, c);
				invalidate();
			}
			idx++;
		}
		palette.over(active);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}
