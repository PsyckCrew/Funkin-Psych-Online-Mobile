package backend.mobile;

import flixel.FlxState;
import flixel.input.IFlxInputManager;
import flixel.input.keyboard.FlxKey;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end
#if mobile
import flixel.system.scaleModes.RatioScaleMode;
import openfl.events.Event;
#end

enum abstract VibrationKind(Int)
{
	var MISS;
	var HIT;
	var HOLD;
}

class MobileUtil implements IFlxInputManager
{
	public static var instance(default, null):MobileUtil;

	public static var enabled(get, never):Bool;
	static function get_enabled():Bool
		return ClientPrefs.data.mobileControls;

	public static var dragStep:Float = 70;
	public static var tapSlop:Float = 20;
	public static var tapMaxTime:Float = 0.4;
	public static var swipeMinDistance:Float = 60;

	static final NO_MENU_TOUCH:Array<String> = ['states.PlayState', 'states.editors.'];
	static final NO_TAP_ACCEPT:Array<String> = ['online.', 'states.TitleState', 'options.NoteOffsetState', 'options.NotesSubState'];

	public static var backPressed(default, null):Bool = false;

	static var escapeHeld:Bool = false;
	static var bindings:Array<{button:TouchButton, key:String, consumeMouse:Bool}> = [];
	static var pulses:Map<String, Int> = [];
	static var lastPulses:Map<String, Int> = [];

	public static function init()
	{
		if (instance != null)
			return;
		instance = FlxG.inputs.add(new MobileUtil());
		FlxG.signals.preStateSwitch.add(() -> bindings = []);
		#if mobile
		initScreen();
		#end
		#if android
		var window = lime.app.Application.current.window;
		window.onKeyUp.add((key, _) -> {
			if (key == lime.ui.KeyCode.APP_CONTROL_BACK)
				window.onKeyUp.cancel();
		}, false, -1000);
		#end
	}

	public static function bind(button:TouchButton, key:String, consumeMouse:Bool = false)
	{
		button.active = false;
		bindings.push({button: button, key: key, consumeMouse: consumeMouse});
	}

	public static function unbind(button:TouchButton)
	{
		bindings = bindings.filter(b -> b.button != button);
	}

	public static function justPressed(key:String):Bool
	{
		if (pulses.get(key) == 1)
			return true;
		for (b in bindings)
			if (b.key == key && b.button.exists && b.button.justPressed)
				return true;
		return false;
	}

	public static function pressed(key:String):Bool
	{
		if (pulses.exists(key))
			return true;
		for (b in bindings)
			if (b.key == key && b.button.exists && b.button.pressed)
				return true;
		return false;
	}

	public static function justReleased(key:String):Bool
	{
		if (lastPulses.exists(key) && !pulses.exists(key))
			return true;
		for (b in bindings)
			if (b.key == key && b.button.exists && b.button.justReleased)
				return true;
		return false;
	}

	public static function pulse(key:String)
	{
		pulses.set(key, 1);
	}

	#if android
	static var haptics:Dynamic;
	#end

	public static function vibrate(kind:VibrationKind)
	{
		var mode = ClientPrefs.data.vibration;
		var strength = ClientPrefs.data.vibrationStrength;
		if (mode == 'Off' || strength <= 0 || (kind == MISS ? mode == 'On Note Hit' : mode == 'On Miss'))
			return;

		var duration = kind == MISS ? 60 : (kind == HIT ? 20 : 12);
		var amplitude = Std.int((kind == HOLD ? 128 : 255) * strength);
		#if android
		if (haptics == null)
			haptics = lime.system.JNI.createStaticMethod('boo/sniro/psychonline/Haptics', 'vibrate', '(II)V');
		haptics(duration, amplitude);
		#elseif mobile
		lime.ui.Haptic.vibrate(0, duration);
		#end
	}

	#if FLX_TOUCH
	public static function getTouchById(id:Int):FlxTouch
	{
		for (t in FlxG.touches.list)
			if (t.touchPointID == id)
				return t;
		return null;
	}

	public static function isAnyTouchInArea(x:Float, y:Float, w:Float, h:Float):Bool
	{
		for (t in FlxG.touches.list)
			if (t.screenX >= x && t.screenX < x + w && t.screenY >= y && t.screenY < y + h)
				return true;
		return false;
	}
	#end

	function new() {}

	public function reset()
	{
		pulses.clear();
		lastPulses.clear();
	}

	function update()
	{
		lastPulses = pulses;
		pulses = [];

		var consumed = false;
		for (b in bindings.copy())
		{
			if (b.button.exists && b.button.visible)
			{
				b.button.update(FlxG.elapsed);
				if (b.consumeMouse && b.button.justPressed)
					consumed = true;
			}
		}

		#if FLX_MOUSE
		if (consumed && FlxG.mouse.justPressed)
			@:privateAccess FlxG.mouse._leftButton.reset();
		#end

		backPressed = false;
		#if android
		var escape = @:privateAccess FlxG.keys.getKey(FlxKey.ESCAPE);
		if (escapeHeld)
		{
			escape.release();
			escapeHeld = false;
		}
		if (FlxG.android.justReleased.BACK)
		{
			backPressed = true;
			pulse('back');
			pulse('pause');
			escape.press();
			escapeHeld = true;
		}
		#end

		var menu = enabled ? currentMenu() : null;
		if (menu != null)
			updateDrag(!startsWithAny(menu, NO_TAP_ACCEPT));
		else
			dragID = -1;
	}

	static function currentMenu():String
	{
		if (FlxG.state == null)
			return null;
		var top:FlxState = FlxG.state;
		while (top.subState != null)
			top = top.subState;
		var name = Type.getClassName(Type.getClass(top));
		return startsWithAny(name, NO_MENU_TOUCH) ? null : name;
	}

	static function startsWithAny(name:String, prefixes:Array<String>):Bool
	{
		for (p in prefixes)
			if (name.startsWith(p))
				return true;
		return false;
	}

	var dragID:Int = -1;
	var dragAnchorY:Float = 0;
	var dragStartX:Float = 0;
	var dragStartY:Float = 0;
	var dragStepped:Bool = false;
	var dragStartTime:Float = 0;

	function updateDrag(tapAccept:Bool)
	{
		#if FLX_TOUCH
		if (dragID >= 0)
		{
			var t = getTouchById(dragID);
			if (t == null || t.justReleased || !t.pressed)
			{
				if (t != null && !dragStepped)
				{
					var dx = t.screenX - dragStartX;
					var dy = t.screenY - dragStartY;
					if (Math.abs(dx) >= swipeMinDistance && Math.abs(dx) > Math.abs(dy) * 1.5)
						pulse(dx < 0 ? 'ui_left' : 'ui_right');
					else if (tapAccept && Math.abs(dx) < tapSlop && Math.abs(dy) < tapSlop && haxe.Timer.stamp() - dragStartTime < tapMaxTime)
						pulse('accept');
				}
				dragID = -1;
			}
			else
			{
				var dy = t.screenY - dragAnchorY;
				if (Math.abs(t.screenX - dragStartX) < Math.abs(t.screenY - dragStartY) * 2 && Math.abs(dy) >= dragStep)
				{
					pulse(dy < 0 ? 'ui_up' : 'ui_down');
					dragAnchorY += dy < 0 ? -dragStep : dragStep;
					dragStepped = true;
				}
			}
		}

		if (dragID < 0)
		{
			for (t in FlxG.touches.list)
			{
				if (!t.justPressed || overButton(t.screenX, t.screenY))
					continue;
				dragID = t.touchPointID;
				dragAnchorY = dragStartY = t.screenY;
				dragStartX = t.screenX;
				dragStepped = false;
				dragStartTime = haxe.Timer.stamp();
				break;
			}
		}
		#end
	}

	static function overButton(x:Float, y:Float):Bool
	{
		for (b in bindings)
		{
			var btn = b.button;
			if (b.consumeMouse && btn.exists && btn.visible && x >= btn.x && x < btn.x + btn.width && y >= btn.y && y < btn.y + btn.height)
				return true;
		}
		return false;
	}

	#if mobile
	static function initScreen()
	{
		FlxG.scaleMode = new RatioScaleMode(false);
		FlxG.stage.addEventListener(Event.RESIZE, _ -> refreshScreen());
		refreshScreen();

		FlxG.signals.preDraw.add(() -> {
			if (FlxG.mouse.cursorContainer != null)
				FlxG.mouse.cursorContainer.visible = false;
		});
	}

	static function refreshScreen()
	{
		var w = FlxG.stage.stageWidth, h = FlxG.stage.stageHeight;
		if (w <= 0 || h <= 0)
			return;
		FlxG.scaleMode.onMeasure(w, h);
		Log.info('[MobileUtil] stage=${w}x${h} game=${FlxG.width}x${FlxG.height} scale=${FlxG.scaleMode.scale.x},${FlxG.scaleMode.scale.y} offset=${FlxG.scaleMode.offset.x},${FlxG.scaleMode.offset.y}');
	}
	#end

	function onFocus() {}

	function onFocusLost()
	{
		reset();
	}

	public function destroy() {}
}
