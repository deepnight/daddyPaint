package ui;

class Hud extends dn.Process {
	public var client(get,never) : Client; inline function get_client() return Client.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Client.ME.fx;

	var invalidated = true;
	var toolBar : h2d.Flow;

	public function new() {
		super(Client.ME);

		createRootInLayers(client.root, Const.DP_UI);

		toolBar = new h2d.Flow(root);
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
		var isVertical = w()>h();

		toolBar.removeChildren();
		toolBar.layout = isVertical ? Vertical : Horizontal;

		var allColors = [client.theme.bg].concat( client.theme.palette );
		var barSize = 0.07 * (isVertical?w():h())/Const.SCALE;
		var btSize = M.ceil( (isVertical?h():w())/Const.SCALE / allColors.length );

		function createButton(col:Col, cb:(i:h2d.Interactive)->Void, isActive:Bool) {
			var i = new h2d.Interactive(isVertical?barSize:btSize, isVertical?btSize:barSize, toolBar);
			i.propagateEvents = true;
			i.backgroundColor = C.addAlphaF(col);
			i.onPush = function(e:hxd.Event) {
				e.propagate = true;
				cb(i);
			}
			i.onClick = function(e:hxd.Event) {
				e.propagate = false;
			}

			var line = new h2d.Bitmap( h2d.Tile.fromColor(White, 1,Std.int(i.height), 1), i);

			if( isActive ) {
				i.width+=7;
				i.filter = new h2d.filter.Glow(col, 1, 64, true);
			}

			line.x = i.width;
			return i;
		}


		// var i : h2d.Interactive = null;

		// Brush size button
		// i = createButton(0xffffff, function() {
		// 	client.baseBrushSize = client.baseBrushSize==10 ? 50 : 10;
		// });

		// Palette
		// var active = null;
		for(c in allColors) {
			var i = createButton(
				c,
				function(i) {
					// Pick color
					client.color = c;
					fx.pickColor(toolBar.x+i.x, toolBar.y+i.y, i.width, i.height, c);
					invalidate();
				},
				c==client.color
			);

			// Active
			// if( c==client.color )
			// 	active = i;
		}
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}
