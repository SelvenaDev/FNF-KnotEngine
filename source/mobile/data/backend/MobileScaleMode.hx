package mobile.data.backend;

import flixel.system.scaleModes.BaseScaleMode;

class MobileScaleMode extends BaseScaleMode
{
	public static var allowWideScreen(default, set):Bool = true;

	public static function refresh():Void
	{
		// Recreate the scale mode immediately after the option changes. This
		// forces Flixel to recalculate gameSize and removes stale letterbox
		// offsets instead of waiting for the next orientation/resize event.
		FlxG.scaleMode = new MobileScaleMode();
		if (ClientPrefs.data.wideScreen && allowWideScreen)
		{
			FlxG.game.x = 0;
			FlxG.game.y = 0;
		}
	}

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		var ratio:Float = FlxG.width / FlxG.height;
		var realRatio:Float = Width / Height;
		var scaleY:Bool = realRatio < ratio;
		if (ClientPrefs.data.wideScreen && allowWideScreen)
			scaleY = !scaleY;

		if (scaleY)
		{
			gameSize.x = Width;
			gameSize.y = Math.floor(gameSize.x / ratio);
		}
		else
		{
			gameSize.y = Height;
			gameSize.x = Math.floor(gameSize.y * ratio);
		}
	}

	@:noCompletion
	private static function set_allowWideScreen(value:Bool):Bool
	{
		allowWideScreen = value;
		FlxG.scaleMode = new MobileScaleMode();
		return value;
	}
}
