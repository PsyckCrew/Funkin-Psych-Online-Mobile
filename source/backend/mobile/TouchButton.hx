package backend.mobile;

import flixel.FlxG;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

enum abstract DragMode(Int) from Int to Int {
	var FREE = 0;
	var CLAIM_ON_PRESS = 1;
	var SLIDE_IN = 2;
}

class TouchButton extends flixel.FlxSprite {

	public var pressed(default, null):Bool = false;
	public var justPressed(default, null):Bool = false;
	public var justReleased(default, null):Bool = false;
	public var holdTime(default, null):Float = 0.0;
	public var touchID(default, null):Int = -1;

	public var enabled:Bool = true;
	public var dragMode:DragMode = CLAIM_ON_PRESS;
	public var releaseOnExit:Bool = false;

	public var idleAlpha(default, set):Float = 0.4;
	public var pressedAlpha(default, set):Float = 0.7;

	public var idleColor(default, set):FlxColor    = FlxColor.WHITE;
	public var pressedColor(default, set):FlxColor = FlxColor.WHITE;
	public var usePressedColor:Bool = false;

	public var onDown:Void->Void = null;
	public var onUp:Void->Void   = null;

	var _prevPressed:Bool = false;

	public function new(x:Float = 0, y:Float = 0) {
		super(x, y);
		scrollFactor.set(0, 0);
		alpha = idleAlpha;
		color = idleColor;
	}

	function set_idleAlpha(v:Float):Float {
		idleAlpha = v;
		if (!pressed) alpha = v;
		return v;
	}

	function set_pressedAlpha(v:Float):Float {
		pressedAlpha = v;
		if (pressed) alpha = v;
		return v;
	}

	function set_idleColor(v:FlxColor):FlxColor {
		idleColor = v;
		if (!pressed) color = v;
		return v;
	}

	function set_pressedColor(v:FlxColor):FlxColor {
		pressedColor = v;
		if (pressed && usePressedColor) color = v;
		return v;
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!enabled) {
			_clearState();
			return;
		}

		_prevPressed = pressed;
		_resolveInput();

		justPressed  = !_prevPressed && pressed;
		justReleased =  _prevPressed && !pressed;

		if (pressed) holdTime += elapsed;
		else         holdTime  = 0.0;

		_applyVisuals();
	}

	function _resolveInput():Void {
		#if FLX_TOUCH
		switch (dragMode) {
			case FREE:
				pressed = MobileUtil.isAnyTouchInArea(x, y, width, height);
				if (!pressed) touchID = -1;
			case CLAIM_ON_PRESS:
				_resolveClaimOnPress();
			case SLIDE_IN:
				_resolveSlideIn();
		}
		#end

		#if (!mobile && FLX_MOUSE)
		if (!pressed) {
			var cam = (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;
			var mp = FlxG.mouse.getWorldPosition(cam);
			pressed = FlxG.mouse.pressed
			       && mp.x >= x && mp.x < x + width
			       && mp.y >= y && mp.y < y + height;
			mp.put();
		}
		#end
	}

	#if FLX_TOUCH
	function _resolveClaimOnPress():Void {
		var cam:FlxCamera = (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;

		if (touchID >= 0) {
			var owned:FlxTouch = MobileUtil.getTouchById(touchID);
			if (owned == null || owned.justReleased) {
				pressed = false;
				touchID = -1;
			} else if (releaseOnExit) {
				var wp = flixel.math.FlxPoint.get();
				owned.getWorldPosition(cam, wp);
				pressed = wp.x >= x && wp.x < x + width && wp.y >= y && wp.y < y + height;
				wp.put();
				if (!pressed) touchID = -1;
			} else {
				pressed = true;
			}
		}

		if (touchID < 0) {
			pressed = false;
			var wp = flixel.math.FlxPoint.get();
			for (t in FlxG.touches.list) {
				if (!t.justPressed || !t.pressed) continue;
				t.getWorldPosition(cam, wp);
				if (wp.x >= x && wp.x < x + width && wp.y >= y && wp.y < y + height) {
					pressed = true;
					touchID = t.touchPointID;
					break;
				}
			}
			wp.put();
		}
	}

	function _resolveSlideIn():Void {
		var cam:FlxCamera = (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;

		if (touchID >= 0) {
			var owned:FlxTouch = MobileUtil.getTouchById(touchID);
			if (owned == null || owned.justReleased) {
				pressed = false;
				touchID = -1;
			} else {
				var wp = flixel.math.FlxPoint.get();
				owned.getWorldPosition(cam, wp);
				if (wp.x >= x && wp.x < x + width && wp.y >= y && wp.y < y + height) pressed = true;
				else { pressed = false; touchID = -1; }
				wp.put();
			}
		}
		if (!pressed) {
			var wp = flixel.math.FlxPoint.get();
			for (t in FlxG.touches.list) {
				if (!t.pressed || t.justReleased) continue;
				t.getWorldPosition(cam, wp);
				if (wp.x >= x && wp.x < x + width && wp.y >= y && wp.y < y + height) {
					pressed = true;
					touchID = t.touchPointID;
					break;
				}
			}
			wp.put();
		}
	}
	#end

	function _applyVisuals():Void {
		if (justPressed) {
			alpha = pressedAlpha;
			if (usePressedColor) color = pressedColor;
			if (onDown != null) onDown();
		} else if (justReleased) {
			alpha = idleAlpha;
			if (usePressedColor) color = idleColor;
			if (onUp != null) onUp();
		}
	}

	function _clearState():Void {
		if (pressed) {
			pressed      = false;
			justPressed  = false;
			justReleased = true;
			holdTime     = 0.0;
			touchID      = -1;
			_applyVisuals();
		} else {
			justPressed = justReleased = false;
		}
	}

	override public function destroy():Void {
		onDown = null;
		onUp   = null;
		super.destroy();
	}
}
