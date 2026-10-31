package backend.mobile;

import backend.mobile.TouchButton.DragMode;

enum abstract HitboxStyle(String) from String to String
{
	var CLASSIC = 'Classic';
	var VSLICE = 'V-Slice';
}

class Hitbox extends FlxSpriteGroup
{
	static final LANE_COLORS:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];
	static final VSLICE_ZONES:Array<Array<Int>> = [[0, 435], [355, 680], [600, 925], [845, 1280]];
	static inline var VSLICE_TOP:Int = 288;

	public var lanes:Array<TouchButton> = [];
	public var style(default, null):HitboxStyle;

	public function new(keys:Array<String>, ?style:HitboxStyle)
	{
		super();
		scrollFactor.set();
		this.style = style ?? ClientPrefs.data.hitboxStyle;

		var top = this.style == VSLICE ? VSLICE_TOP : 0;
		var laneW = Std.int(FlxG.width / keys.length);
		for (i in 0...keys.length)
		{
			var left = laneW * i;
			var right = left + laneW;
			if (this.style == VSLICE && keys.length == 4)
			{
				left = VSLICE_ZONES[i][0];
				right = VSLICE_ZONES[i][1];
			}

			var lane = new TouchButton(left, top);
			lane.makeGraphic(right - left, FlxG.height - top, FlxColor.TRANSPARENT, true);
			lane.dragMode = SLIDE_IN;
			lane.antialiasing = false;
			if (this.style == VSLICE)
			{
				lane.idleAlpha = 0;
				lane.pressedAlpha = 0;
			}
			else
			{
				drawLane(lane, keys.length == 4 ? LANE_COLORS[i] : FlxColor.fromHSB(360 * i / keys.length, 0.75, 1));
				lane.idleAlpha = 0.15;
				lane.pressedAlpha = 0.6;
			}
			add(lane);
			lanes.push(lane);
			MobileUtil.bind(lane, keys[i]);
		}
	}

	static function drawLane(lane:FlxSprite, color:FlxColor)
	{
		var w = Std.int(lane.width), h = Std.int(lane.height);
		var fill:FlxColor = color;
		fill.alpha = 0x30;
		var pixels = lane.pixels;
		pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, h), fill);
		pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, 4), color);
		pixels.fillRect(new openfl.geom.Rectangle(0, h - 4, w, 4), color);
		pixels.fillRect(new openfl.geom.Rectangle(0, 0, 4, h), color);
		pixels.fillRect(new openfl.geom.Rectangle(w - 4, 0, 4, h), color);
		lane.dirty = true;
	}

	override function destroy()
	{
		for (lane in lanes)
			MobileUtil.unbind(lane);
		lanes = null;
		super.destroy();
	}
}
