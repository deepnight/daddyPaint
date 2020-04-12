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

	public inline function isVertical() return h()>w();
	public inline function isHorizontal() return !isVertical();

	override function onDispose() {
		super.onDispose();
	}

	public inline function invalidate() invalidated = true;

	override function onResize() {
		super.onResize();
		invalidate();
	}

	function render() {
		toolBar.removeChildren();
		toolBar.layout = isHorizontal() ? Vertical : Horizontal;
		toolBar.horizontalAlign = Left;
		toolBar.verticalAlign = Top;

		var allColors = [client.theme.bg].concat( client.theme.palette );
		var barSize = 0.07 * (isHorizontal()?w():h())/Const.SCALE;
		var btSize = M.ceil( (isHorizontal()?h():w())/Const.SCALE / (allColors.length+1) );

		function createButton(col:UInt, cb:h2d.Interactive->Void) {
			var i = new h2d.Interactive(isHorizontal()?barSize:btSize, isHorizontal()?btSize:barSize, toolBar);
			i.propagateEvents = true;
			i.backgroundColor = C.addAlphaF(col);
			i.onPush = function(e:hxd.Event) {
				e.propagate = false;
				cb(i);
			}
			i.onClick = function(e:hxd.Event) {
				e.propagate = false;
			}
			return i;
		}

		// Brush size button
		var i = createButton(0xffffff, function(i) {
			client.baseBrushSize = client.baseBrushSize==10 ? 50 : 10;
		});

		// Palette
		var active = null;
		for(c in allColors) {
			var i = createButton(c, function(i) {
				// Pick color
				client.color = c;
				fx.pickColor(toolBar.x+i.x, toolBar.y+i.y, i.width, i.height, c);
				invalidate();
			});

			// Active
			if( c==client.color ) {
				active = i;
				if( isVertical() )
					i.height+=7;
				else
					i.width+=7;
				i.filter = new h2d.filter.Glow(c, 1, 64, true);
			}
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
