package funkin.states;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;

import funkin.states.editors.MasterEditorMenu;
import funkin.options.OptionsState;

class MainMenuState extends MusicBeatState
{
	public static var knotEngineVersion:String = '7.0.0'; // Latest Version bcuz v1.0.0 so late these days and This is also used for Discord RPC
	public static var psychEngineVersion:String = '0.7.3';
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED
		'mods',
		#end
		#if ACHIEVEMENTS_ALLOWED
		'awards',
		#end
		'credits',
		'options'
	];

	var knotEngineLogo:FlxSprite;

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		
		switch (ClientPrefs.data.themes) {
			case 'Base Game':
				magenta.color = 0xFFFD719B;

			case 'Knot Engine':
				magenta.color = 0xFF000080;
		}
		
		add(magenta);

		if (ClientPrefs.data.lowQuality == false)
		{
			var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
			grid.velocity.set(40, 40);
			grid.scrollFactor.set(0, 0);
			grid.alpha = 0;
			FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
			add(grid);
		}

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			// menuItem.screenCenter(X);
			menuItem.x = 95;
		}

		knotEngineLogo = new FlxSprite(735, 0).loadGraphic(Paths.image('knotEngineLogo'));
		knotEngineLogo.scrollFactor.set(0, 0);
		knotEngineLogo.antialiasing = ClientPrefs.data.antialiasing;
		knotEngineLogo.visible = true;
		knotEngineLogo.setGraphicSize(Std.int(bg.width * 0.32));
		knotEngineLogo.updateHitbox();
		knotEngineLogo.screenCenter(Y);
		knotEngineLogo.scale.set(0.4, 0.4);
		add(knotEngineLogo);

		var knotVer:FlxText = new FlxText(12, FlxG.height - 64, 0, "Knot Engine v" + knotEngineVersion, 12);
		knotVer.scrollFactor.set();
		knotVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(knotVer);
		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if mobile
		addTouchPad("UP_DOWN", "A_B_E");
		#end

		super.create();

		FlxG.camera.follow(camFollow, null, 9);
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			#if mobile
			if (controls.ACCEPT)
			{
				confirmMenuSelection();
			}
			else if (controls.justPressed('debug_1') || touchPad.buttonE.justPressed)
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#else
			if (controls.ACCEPT)
			{
				confirmMenuSelection();
			}
			else if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	private function confirmMenuSelection():Void
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));
		selectedSomethin = true;

		if (ClientPrefs.data.flashing)
			FlxFlicker.flicker(magenta, 1.1, 0.15, false);

			var selectedIndex:Int = curSelected;
			var selectedItem:FlxSprite = menuItems.members[selectedIndex];
			var originalX:Float = selectedItem.x;

			// The selected menu item moves horizontally to the right only.
			// Do not change Y here, otherwise it appears to move diagonally.
			FlxTween.tween(selectedItem, {x: originalX + 220}, 0.2,
		{
			ease: FlxEase.quadOut,
			onComplete: function(firstTween:FlxTween)
			{
					FlxTween.tween(selectedItem, {x: originalX}, 0.48,
				{
					ease: FlxEase.bounceOut,
					onComplete: function(landingTween:FlxTween)
					{
							for (i in 0...menuItems.members.length)
							{
								var item:FlxSprite = menuItems.members[i];
								if (item == null) continue;
								// Keep Main Menu consistent with Freeplay: no split and no
								// downward fall. Slide every menu item to the left.
								var slideX:Float = item.x - FlxG.width - 180;
								FlxTween.tween(item, {x: slideX, alpha: 0}, 0.55,
								{
									ease: FlxEase.quadIn,
									onComplete: function(slideTween:FlxTween)
									{
										if (item == selectedItem)
											switchToSelectedMenu();
									}
								});
							}
					}
				});
			}
		});
	}

	private function switchToSelectedMenu():Void
	{
		switch (optionShit[curSelected])
		{
			case 'story_mode':
				MusicBeatState.switchState(new StoryMenuState());
			case 'freeplay':
				MusicBeatState.switchState(new FreeplayState());

			#if MODS_ALLOWED
			case 'mods':
				MusicBeatState.switchState(new ModsMenuState());
			#end

			#if ACHIEVEMENTS_ALLOWED
			case 'awards':
				MusicBeatState.switchState(new AchievementsMenuState());
			#end

			case 'credits':
				MusicBeatState.switchState(new CreditsState());
			case 'options':
				OptionsState.onPlayState = false;
				MusicBeatState.switchState(new OptionsState());
		}
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].updateHitbox();
		// menuItems.members[curSelected].screenCenter(X);

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();
		// menuItems.members[curSelected].screenCenter(X);

		camFollow.setPosition(menuItems.members[curSelected].getGraphicMidpoint().x,
			menuItems.members[curSelected].getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
	}
}
