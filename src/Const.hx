class Const {
	public static var FPS = 60;
	public static var FIXED_FPS = 30;
	public static var AUTO_SCALE_TARGET_WID = 1000; // -1 to disable auto-scaling on width
	public static var AUTO_SCALE_TARGET_HEI = -1; // -1 to disable auto-scaling on height
	public static var SCALE = 1.0; // ignored if auto-scaling
	public static var UI_SCALE = 1.0;
	public static var GRID = 16;

	static var _uniq = 0;
	public static var NEXT_UNIQ(get,never) : Int; static inline function get_NEXT_UNIQ() return _uniq++;
	public static var INFINITE = 999999;

	static var _inc = 0;
	public static var DP_BG = _inc++;
	public static var DP_FX_BG = _inc++;
	public static var DP_MAIN = _inc++;
	public static var DP_FRONT = _inc++;
	public static var DP_UI = _inc++;
	public static var DP_FX_FRONT = _inc++;
	public static var DP_TOP = _inc++;

	public static var THEMES : Array<Theme> = [
		{ // dark
			isLight: false,
			bg: Color.hexToInt("#1a1c2c"),
			palette: [
				Color.hexToInt("#FFcc00"),
				Color.hexToInt("#FF3124"),
				Color.hexToInt("#A95431"),
				Color.hexToInt("#FF2674"),
				Color.hexToInt("#9354FF"),
				Color.hexToInt("#4998D4"),
				Color.hexToInt("#54D3B5"),
				Color.hexToInt("#B0EF44"),
				Color.hexToInt("#3C6B3F"),
			],
		},
		{ // light
			isLight: true,
			bg: Color.hexToInt("#f3efd8"),
			palette: [
				Color.hexToInt("#A95431"),
				Color.hexToInt("#FFcc00"),
				Color.hexToInt("#FF3124"),
				Color.hexToInt("#CF1272"),
				Color.hexToInt("#9354FF"),
				Color.hexToInt("#4998D4"),
				Color.hexToInt("#54D3B5"),
				Color.hexToInt("#B0EF44"),
				Color.hexToInt("#3C6B3F"),
				Color.hexToInt("#ffffff"),
				Color.hexToInt("#1e2a2f"),
			],
		},
	];
}
