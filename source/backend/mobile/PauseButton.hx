package backend.mobile;

class PauseButton extends TouchButton
{
	public function new()
	{
		super();
		loadGraphic(Paths.image('mobile/pause'));
		antialiasing = ClientPrefs.data.antialiasing;
		setPosition(FlxG.width - width - 35, 35);
		idleAlpha = 0.6;
		pressedAlpha = 1;
		MobileUtil.bind(this, 'pause', true);
	}

	override function destroy()
	{
		MobileUtil.unbind(this);
		super.destroy();
	}
}
