import h2d.Sprite;
import dn.heaps.HParticle;
import dn.Tweenie;


class Fx extends dn.Process {
	public var pool : ParticlePool;

	public var bgAddSb    : h2d.SpriteBatch;
	public var bgNormalSb    : h2d.SpriteBatch;
	public var topAddSb       : h2d.SpriteBatch;
	public var topNormalSb    : h2d.SpriteBatch;

	var client(get,never) : Client; inline function get_client() return Client.ME;

	public function new() {
		super(Client.ME);

		pool = new ParticlePool(Assets.tiles.tile, 2048, Const.FPS);

		bgAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		client.root.add(bgAddSb, Const.DP_FX_BG);
		bgAddSb.blendMode = Add;
		bgAddSb.hasRotationScale = true;

		bgNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		client.root.add(bgNormalSb, Const.DP_FX_BG);
		bgNormalSb.hasRotationScale = true;

		topNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		client.root.add(topNormalSb, Const.DP_FX_FRONT);
		topNormalSb.hasRotationScale = true;

		topAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		client.root.add(topAddSb, Const.DP_FX_FRONT);
		topAddSb.blendMode = Add;
		topAddSb.hasRotationScale = true;
	}

	override public function onDispose() {
		super.onDispose();

		pool.dispose();
		bgAddSb.remove();
		bgNormalSb.remove();
		topAddSb.remove();
		topNormalSb.remove();
	}

	public function clear() {
		pool.killAll();
	}

	public inline function allocTopAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topAddSb, t, x, y);
	}

	public inline function allocTopNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topNormalSb, t,x,y);
	}

	public inline function allocBgAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgAddSb, t,x,y);
	}

	public inline function allocBgNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgNormalSb, t,x,y);
	}

	public inline function getTile(id:String) : h2d.Tile {
		return Assets.tiles.getTileRandom(id);
	}

	public function killAll() {
		pool.killAll();
	}

	public function markerCase(cx:Int, cy:Int, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile("fxCircle"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.lifeS = sec;

		var p = allocTopAdd(getTile("pixel"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(2);
		p.lifeS = sec;
		#end
	}

	public function markerFree(x:Float, y:Float, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile("fxDot"), x,y);
		p.setCenterRatio(0.5,0.5);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(3);
		p.lifeS = sec;
		#end
	}

	public function markerText(cx:Int, cy:Int, txt:String, ?t=1.0) {
		#if debug
		var tf = new h2d.Text(Assets.fontTiny, topNormalSb);
		tf.text = txt;

		var p = allocTopAdd(getTile("fxCircle"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.colorize(0x0080FF);
		p.alpha = 0.6;
		p.lifeS = 0.3;
		p.fadeOutSpeed = 0.4;
		p.onKill = tf.remove;

		tf.setPosition(p.x-tf.textWidth*0.5, p.y-tf.textHeight*0.5);
		#end
	}

	public function flashBangS(c:UInt, a:Float, ?t=0.1) {
		var e = new h2d.Bitmap(h2d.Tile.fromColor(c,1,1,a));
		client.root.add(e, Const.DP_FX_FRONT);
		e.scaleX = client.w();
		e.scaleY = client.h();
		e.blendMode = Add;
		client.tw.createS(e.alpha, 0, t).end( function() {
			e.remove();
		});
	}

	public function smokeTap(x:Float,y:Float,c:UInt) {
		var n = 35;
		for(i in 0...n ) {
			var a = 6.28 * i/n + rnd(0,0.2,true);
			var p = allocBgAdd(getTile("fxSmoke"), x+Math.cos(a)*rnd(5,10), y+Math.sin(a)*rnd(5,10));
			p.colorAnimS( c, Const.BG_COLOR, rnd(0.7,1.3) );
			p.setScale(rnd(3,4,true));
			p.setFadeS(rnd(0.07,0.10), rnd(0.1,0.3), rnd(1,2));
			p.moveAwayFrom(x,y,rnd(2,5));
			p.frict = rnd(0.96,0.97);
			p.rotation = rnd(0,6.28);
			p.dr = rnd(0,0.01,true);
			p.ds = rnd(0.002,0.005);
			p.lifeS = rnd(0.3,0.5);
		}
	}

	public function segment(fx:Float,fy:Float, tx:Float, ty:Float, c:UInt) {
		var dist = M.dist(fx,fy,tx,ty);
		var ang = Math.atan2(ty-fy, tx-fx);
		var n = M.ceil( dist/5 );
		var step = dist/n;
		for(i in 0...n ) {
			var r = i/n;
			var p = allocBgAdd(
				getTile("fxLine"),
				fx+Math.cos(ang)*dist*r + rnd(0,10,true),
				fy+Math.sin(ang)*dist*r + rnd(0,10,true)
			);
			p.setFadeS(rnd(0.4,0.7), rnd(0.1,0.3), rnd(2,2.5));
			p.colorAnimS(c, Const.BG_COLOR, rnd(0.1,0.3));
			p.setScale(rnd(2,3,true));
			p.moveAng(ang, rnd(3,5));
			p.frict = rnd(0.96,0.97);
			p.rotation = ang;
			p.scaleX = step;
			p.scaleY = rnd(2,3);
			p.scaleXMul = rnd(0.97,0.98);
			p.lifeS = rnd(0.4,0.7);
		}
	}

	override function update() {
		super.update();

		pool.update(client.tmod);
	}
}