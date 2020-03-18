package ui;

class Hud extends dn.Process {
	public var client(get,never) : Client; inline function get_client() return Client.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Client.ME.fx;

	var invalidated = true;
	var left : h2d.Layers;

	public function new() {
		super(Client.ME);

		createRootInLayers(client.root, Const.DP_UI);

		left = new h2d.Layers(root);
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
		left.removeChildren();

		var allColors = [client.theme.bg].concat( client.theme.palette );
		// var allColors = client.theme.palette.concat([client.theme.bg]);
		var btHei = M.ceil( h()/Const.SCALE / (allColors.length+1) );
		var btWid = 0.07 * w()/Const.SCALE;

		var i = new h2d.Interactive(btWid, btHei, left);
		i.propagateEvents = true;
		i.backgroundColor = C.addAlphaF(0xffffff);
		i.onClick = function(_) {
			client.baseBrushSize = client.baseBrushSize==10 ? 50 : 10;
		}

		// Palette
		var idx = 1;
		var active = null;
		for(c in allColors) {
			var i = new h2d.Interactive(btWid, btHei, left);
			i.propagateEvents = true;
			i.y = btHei*idx;

			if( c==client.color ) {
				active = i;
				i.width+=7;
				i.filter = new h2d.filter.Glow(c, 1, 64, true);
				i.backgroundColor = C.addAlphaF(c);
			}
			else
				i.backgroundColor = C.addAlphaF( C.toBlack(c,0.1) );

			i.onPush = function(_) {
				// Select color
				client.color = c;
				fx.pickColor(left.x+i.x, left.y+i.y, i.width, i.height, c);
				invalidate();
			}
			idx++;
		}
		left.over(active);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}
