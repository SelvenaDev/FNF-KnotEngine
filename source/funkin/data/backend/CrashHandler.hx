package funkin.data.backend;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import haxe.io.Path;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if mobile
import mobile.data.backend.StorageUtil;
#end

using StringTools;

class CrashHandler
{
	private static var initialized:Bool = false;
	private static var handlingError:Bool = false;

	public static function init():Void
	{
		if (initialized) return;
		initialized = true;

		try
		{
			openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
				UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		}
		catch (e:Dynamic)
		{
			trace('Could not register uncaught error handler: ' + safeString(e));
		}

		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		if (handlingError) return;
		handlingError = true;

		try
		{
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
		}
		catch (_:Dynamic) {}

		var message:String = formatError(e == null ? null : e.error);
		finishCrash(message, 'Uncaught OpenFL error');
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		if (handlingError) return;
		handlingError = true;
		finishCrash(formatError(message), 'Critical runtime error');
	}
	#end

	private static function finishCrash(message:String, kind:String):Void
	{
		var report:String = buildReport(kind, message);

		#if sys
		saveErrorMessage(report);
		#end

		try
		{
			CoolUtil.showPopUp(message, 'Error!');
		}
		catch (_:Dynamic)
		{
			trace(report);
		}

		#if DISCORD_ALLOWED
		try DiscordClient.shutdown() catch (_:Dynamic) {}
		#end

		try
			lime.system.System.exit(1);
		catch (_:Dynamic)
			trace(report);
	}

	private static function formatError(value:Dynamic):String
	{
		if (value == null) return 'Unknown error';

		try
		{
			if (Std.isOfType(value, Error))
				return Std.string(cast(value, Error).message);
			if (Std.isOfType(value, ErrorEvent))
				return Std.string(cast(value, ErrorEvent).text);
			return Std.string(value);
		}
		catch (_:Dynamic)
			return 'Unprintable error object';
	}

	private static function buildReport(kind:String, message:String):String
	{
		var lines:Array<String> = [];
		lines.push('Knot Engine crash report');
		lines.push('Time: ' + Date.now().toString());
		lines.push('Type: ' + kind);
		lines.push('Platform: ' + Main.platform);
		lines.push('Message: ' + message);
		lines.push('');
		lines.push('Exception stack:');
		try lines.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)))
		catch (_:Dynamic) lines.push('<unavailable>');
		lines.push('');
		lines.push('Call stack:');
		try lines.push(haxe.CallStack.toString(haxe.CallStack.callStack()))
		catch (_:Dynamic) lines.push('<unavailable>');
		return lines.join('\n');
	}

	private static function safeString(value:Dynamic):String
	{
		try return Std.string(value) catch (_:Dynamic) return '<unprintable>';
	}

	#if sys
	private static function saveErrorMessage(message:String):Void
	{
		try
		{
			var baseDir:String = #if mobile StorageUtil.getStorageDirectory() #else Sys.getCwd() #end;
			if (baseDir == null || baseDir.length == 0) baseDir = Sys.getCwd();

			var logDir:String = Path.join([baseDir, 'logs']);
			if (!FileSystem.exists(logDir)) FileSystem.createDirectory(logDir);

			var stamp:String = Date.now().getTime() + '';
			var logFile:String = Path.join([logDir, 'crash-' + stamp + '.log']);
			File.saveContent(logFile, message);
			trace('Crash report saved to: ' + logFile);
		}
		catch (e:Dynamic)
		{
			trace('Could not save crash report: ' + safeString(e));
		}
	}
	#end
}
