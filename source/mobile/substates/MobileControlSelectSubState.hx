package mobile.options;

import mobile.data.backend.MobileScaleMode;
import mobile.data.backend.MobileData;

import flixel.input.keyboard.FlxKey;

import funkin.options.BaseOptionsMenu;
import funkin.options.Option;

class MobileOptionsSubState extends BaseOptionsMenu
{
	#if android
	var storageTypes:Array<String> = ["EXTERNAL_DATA", "EXTERNAL_OBB", "EXTERNAL_MEDIA", "EXTERNAL"];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	final lastStorageType:String = ClientPrefs.data.storageType;
	#end
	final exControlTypes:Array<String> = ["NONE", "SINGLE", "DOUBLE"];
	final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];
	var option:Option;

	public function new()
	{
		#if android if (!externalPaths.contains('\n'))
			storageTypes = storageTypes.concat(externalPaths); #end
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu'; // for Discord Rich Presence, fuck it

		option = new Option('Extra Controls',
			"Select how many extra buttons you prefer to have?\nThey can be used for mechanics with LUA or HScript.",
			'extraButtons',
			'string',
			exControlTypes);
		addOption(option);

		option = new Option('Mobile Controls Opacity',
			"Selects the opacity for the mobile buttons (careful not to put it at 0 and lose track of your buttons).",
			'controlsAlpha',
			'percent');
		option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = () ->
		{
			touchPad.alpha = curOption.getValue();
			ClientPrefs.toggleVolumeKeys();
		};
		addOption(option);

		#if mobile
		option = new Option('Allow Phone Screensaver',
			"If checked, the phone will sleep after going inactive for few seconds.\n(The time depends on your phone\'s options)",
			'screensaver',
			'bool');
		option.onChange = () -> lime.system.System.allowScreenTimeout = curOption.getValue();
		addOption(option);

			option = new Option('Remove Black Bars',
				"If checked, the game stretches to fill the whole screen instead of keeping black bars.",
				'wideScreen',
				'bool');
			option.onChange = () -> MobileScaleMode.refresh();
			addOption(option);
		#end

		if (MobileData.mode == 3)
		{
			option = new Option('Hitbox Design',
				"Choose how your hitbox should look like.",
				'hitboxType',
				'string',
				hintOptions);
			addOption(option);

			option = new Option('Hitbox Position',
				"If checked, the hitbox will be put at the bottom of the screen, otherwise will stay at the top.",
				'hitboxPos',
				'bool');
			addOption(option);
		}

		option = new Option('Dynamic Controls Color',
			"If checked, the mobile controls color will be set to the notes color in your settings.\n(have effect during gameplay only)",
			'dynamicColors',
			'bool');
		addOption(option);

		#if android
		option = new Option('Storage Type',
			"Which folder Psych Engine should use?\n(CHANGING THIS MAKES DELETE YOUR OLD FOLDER!!)",
			'storageType',
			'string',
			storageTypes);
		addOption(option);
		#end

		#if android
		option = new Option('Pause Button',
			"If unchecked, remove pause button from play zone.\n(you can use BACK button in both cases)",
			'pauseButton',
			'bool');
		addOption(option);

		#end

		super();
	}

	#if android
	function onStorageChange():Void
	{
		File.saveContent(lime.system.System.applicationStorageDirectory + 'storagetype.txt', ClientPrefs.data.storageType);

		var lastStoragePath:String = StorageType.fromStrForce(lastStorageType) + '/';

		try
		{
			if (ClientPrefs.data.storageType != "EXTERNAL")
				Sys.command('rm', ['-rf', lastStoragePath]);
		}
		catch (e:haxe.Exception)
			trace('Failed to remove last directory. (${e.message})');
	}

	#end

	override public function destroy()
	{
		super.destroy();
		#if android
		if (ClientPrefs.data.storageType != lastStorageType)
		{
			onStorageChange();
			CoolUtil.showPopUp('Storage Type has been changed and you needed restart the game!!\nPress OK to close the game.', 'Notice!');
			lime.system.System.exit(0);
		}

		#end
		curOption += change;

		if (curOption < 0)
			curOption = options.length - 1;
		if (curOption >= options.length)
			curOption = 0;

		switch (curOption)
		{
			case 0 | 1 | 3:
				reset.visible = false;
				changeControls();
			case 4:
				reset.visible = false;
				changeControls();
				showOfficialPlayerStrums();
			case 2:
				reset.visible = true;
				changeControls();
			case 5:
				reset.visible = true;
				changeControls(0, true);
				control.touchPad.forEachAlive((button:TouchButton) ->
				{
					var ignore = ['G', 'S'];
					if (!ignore.contains(button.tag.toUpperCase()))
						button.visible = button.active = false;
				});
		}
		updatePosText();
		setOptionText();
	}

	private inline function mobilePlayerNoteSpacing():Float
	{
		var amplification:Float = (FlxG.width / FlxG.height) / (FlxG.initialWidth / FlxG.initialHeight);
		return Note.swagWidth * ((FlxG.height / FlxG.width) * 3.2) * amplification;
	}

	private inline function mobilePlayerLaneX(lane:Int):Float
	{
		var arrowWidth:Float = Note.swagWidth;
		var spacing:Float = mobilePlayerNoteSpacing();
		var groupWidth:Float = arrowWidth + spacing * 3;
		return ((FlxG.width - groupWidth) * 0.5) + (spacing * lane);
	}

	function showOfficialPlayerStrums():Void
	{
		officialPlayerStrums = new FlxTypedGroup<StrumNote>();
		officialPlayerStrums.cameras = [ui];
		add(officialPlayerStrums);
		officialStrumTouchState = [false, false, false, false];

		var strumLineX:Float = 0;
		var strumLineY:Float = 0;

		for (i in 0...4)
		{
			var receptor:StrumNote = new StrumNote(strumLineX, strumLineY, i, 1);
			receptor.downScroll = true;
			receptor.updateHitbox();
			officialPlayerStrums.add(receptor);
			receptor.postAddedToGroup();
			receptor.x = mobilePlayerLaneX(i) - 75;
			if(i > 1) receptor.x = mobilePlayerLaneX(i) + 75;
			receptor.y = FlxG.height - receptor.height - 95;
			receptor.alpha = 1;
			receptor.visible = true;
			receptor.cameras = [ui];
		}
	}

	function updateOfficialStrumTouch():Void
	{
		if (officialPlayerStrums == null) return;

		var touched:Array<Bool> = [false, false, false, false];
		for (touch in FlxG.touches.list)
		{
			if (!touch.pressed) continue;
			var point:FlxPoint = touch.getScreenPosition(ui, FlxPoint.get());

			for (lane in 0...4)
			{
				var receptor:StrumNote = officialPlayerStrums.members[lane];
				if (receptor == null || !receptor.exists) continue;

				var laneLeft:Float = receptor.x;
				var laneRight:Float = receptor.x + receptor.width;
				var laneTop:Float = receptor.y - receptor.height * 0.35;
				var laneBottom:Float = receptor.y + receptor.height * 1.35;
				if (point.x >= laneLeft && point.x <= laneRight
					&& point.y >= laneTop && point.y <= laneBottom)
					touched[lane] = true;
			}

			for (pairStart in [0, 2])
			{
				var first:StrumNote = officialPlayerStrums.members[pairStart];
				var second:StrumNote = officialPlayerStrums.members[pairStart + 1];
				if (first == null || second == null || !first.exists || !second.exists) continue;

				var gapLeft:Float = first.x + first.width;
				var gapRight:Float = second.x;
				var gapTop:Float = Math.max(first.y - first.height * 0.35, second.y - second.height * 0.35);
				var gapBottom:Float = Math.min(first.y + first.height * 1.35, second.y + second.height * 1.35);
				if (gapRight > gapLeft && point.x >= gapLeft && point.x <= gapRight
					&& point.y >= gapTop && point.y <= gapBottom)
				{
					touched[pairStart] = true;
					touched[pairStart + 1] = true;
				}
			}
			point.put();
		}

		for (lane in 0...4)
		{
			var receptor:StrumNote = officialPlayerStrums.members[lane];
			if (receptor == null) continue;
			if (touched[lane] && !officialStrumTouchState[lane])
				receptor.playAnim('pressed');
			else if (!touched[lane] && officialStrumTouchState[lane])
				receptor.playAnim('static');
			officialStrumTouchState[lane] = touched[lane];
		}
	}

	function setOptionText()
	{
		itemText.text = options[curOption].replace('-', ' ');
		itemText.updateHitbox();
		itemText.offset.set(0, 15);
		FlxTween.tween(rightArrow, {x: itemText.x + itemText.width + 10}, 0.1, {ease: FlxEase.quintOut});
	}

	function updatePosText()
	{
		var optionName = options[curOption];
		if (optionName == 'Pad-Custom' || optionName == 'Pad-Extra')
		{
			positionText.visible = positionTextBg.visible = true;
			if (optionName == 'Pad-Custom')
			{
				positionText.text = 'LEFT X: ${control.touchPad.buttonLeft.x} - Y: ${control.touchPad.buttonLeft.y}\nDOWN X: ${control.touchPad.buttonDown.x} - Y: ${control.touchPad.buttonDown.y}\n\nUP X: ${control.touchPad.buttonUp.x} - Y: ${control.touchPad.buttonUp.y}\nRIGHT X: ${control.touchPad.buttonRight.x} - Y: ${control.touchPad.buttonRight.y}';
			}
			else
			{
				positionText.text = 'S X: ${control.touchPad.buttonExtra.x} - Y: ${control.touchPad.buttonExtra.y}\n\n\n\nG X: ${control.touchPad.buttonExtra2.x} - Y: ${control.touchPad.buttonExtra2.y}';
			}
			positionText.setPosition(0, (((positionTextBg.height - positionText.height) / 2) + positionTextBg.y));
		}
		else
			positionText.visible = positionTextBg.visible = false;
	}

	function checkArrowButton(button:FlxSprite, func:Void->Void)
	{
		if (TouchUtil.overlaps(button))
		{
			if (TouchUtil.pressed)
				button.animation.play('press');
			if (TouchUtil.justPressed)
			{
				if (options[curOption] == "Pad-Extra" && control.touchPad != null)
					control.touchPad.setExtrasDefaultPos();
				func();
			}
		}
		if (TouchUtil.justReleased && button.animation.curAnim.name == 'press')
			button.animation.play('idle');
		if (FlxG.keys.justPressed.LEFT && button == leftArrow || FlxG.keys.justPressed.RIGHT && button == rightArrow)
			func();
	}

	function moveButton(touch:FlxTouch, button:TouchButton):Void
	{
		bindButton = button;
		buttonBinded = bindButton == null ? false : true;
		bindButton.x = touch.x - Std.int(bindButton.width / 2);
		bindButton.y = touch.y - Std.int(bindButton.height / 2);
		updatePosText();
	}
}
