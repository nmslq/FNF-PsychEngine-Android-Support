package psychlua;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import flixel.util.FlxSave;
import openfl.utils.Assets;

//
// Things to trivialize some dumb stuff like splitting strings on older Lua
//

class ExtraFunctions
{
	public static function implement(funk:FunkinLua)
	{
		// Keyboard & Gamepads
		funk.set("keyboardJustPressed", function(name:String)
		{
			return Reflect.getProperty(FlxG.keys.justPressed, name.toUpperCase());
		});
		funk.set("keyboardPressed", function(name:String)
		{
			return Reflect.getProperty(FlxG.keys.pressed, name.toUpperCase());
		});
		funk.set("keyboardReleased", function(name:String)
		{
			return Reflect.getProperty(FlxG.keys.justReleased, name.toUpperCase());
		});

		funk.set("anyGamepadJustPressed", function(name:String)
		{
			return FlxG.gamepads.anyJustPressed(name.toUpperCase());
		});
		funk.set("anyGamepadPressed", function(name:String)
		{
			return FlxG.gamepads.anyPressed(name.toUpperCase());
		});
		funk.set("anyGamepadReleased", function(name:String)
		{
			return FlxG.gamepads.anyJustReleased(name.toUpperCase());
		});

		funk.set("gamepadAnalogX", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return 0.0;
			}
			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		funk.set("gamepadAnalogY", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return 0.0;
			}
			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		funk.set("gamepadJustPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return false;
			}
			return Reflect.getProperty(controller.justPressed, name.toUpperCase()) == true;
		});
		funk.set("gamepadPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return false;
			}
			return Reflect.getProperty(controller.pressed, name.toUpperCase()) == true;
		});
		funk.set("gamepadReleased", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return false;
			}
			return Reflect.getProperty(controller.justReleased, name.toUpperCase()) == true;
		});

		funk.set("keyJustPressed", function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_P;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_P;
				case 'up': return PlayState.instance.controls.NOTE_UP_P;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_P;
				default: return PlayState.instance.controls.justPressed(name);
			}
			return false;
		});
		funk.set("keyPressed", function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT;
				case 'down': return PlayState.instance.controls.NOTE_DOWN;
				case 'up': return PlayState.instance.controls.NOTE_UP;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT;
				default: return PlayState.instance.controls.pressed(name);
			}
			return false;
		});
		funk.set("keyReleased", function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_R;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_R;
				case 'up': return PlayState.instance.controls.NOTE_UP_R;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_R;
				default: return PlayState.instance.controls.justReleased(name);
			}
			return false;
		});

		// Save data management
		funk.set("initSaveData", function(name:String, ?folder:String = 'psychenginemods') {
			if(!PlayState.instance.modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				// folder goes unused for flixel 5 users. @BeastlyGhost
				save.bind(name, CoolUtil.getSavePath() + '/' + folder);
				PlayState.instance.modchartSaves.set(name, save);
				return;
			}
			FunkinLua.luaTrace('initSaveData: Save file already initialized: ' + name);
		});
		funk.set("flushSaveData", function(name:String) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				PlayState.instance.modchartSaves.get(name).flush();
				return;
			}
			FunkinLua.luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		funk.set("getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				var saveData = PlayState.instance.modchartSaves.get(name).data;
				if(Reflect.hasField(saveData, field))
					return Reflect.field(saveData, field);
				else
					return defaultValue;
			}
			FunkinLua.luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return defaultValue;
		});
		funk.set("setDataFromSave", function(name:String, field:String, value:Dynamic) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
				return;
			}
			FunkinLua.luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});

		// File management
		funk.set("checkFileExists", function(filename:String, ?absolute:Bool = false) {
			#if MODS_ALLOWED
			if(absolute)
				return FileSystem.exists(filename);

			var path:String = Paths.modFolders(filename);
			if(FileSystem.exists(path))
			{
				return true;
			}
			return FileSystem.exists(Paths.getPath('assets/$filename', TEXT));
			#else
			if(absolute)
			{
				return Assets.exists(filename);
			}
			return Assets.exists(Paths.getPath('assets/$filename', TEXT));
			#end
		});
		funk.set("saveFile", function(path:String, content:String, ?absolute:Bool = false)
		{
			try {
				#if LUA_ALLOWED
				if(!absolute)
					File.saveContent(Paths.mods(path), content);
				else
				#end
					File.saveContent(path, content);

				return true;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.set("deleteFile", function(path:String, ?ignoreModFolders:Bool = false)
		{
			try {
				#if MODS_ALLOWED
				if(!ignoreModFolders)
				{
					var lePath:String = Paths.modFolders(path);
					if(FileSystem.exists(lePath))
					{
						FileSystem.deleteFile(lePath);
						return true;
					}
				}
				#end

				var lePath:String = Paths.getPath(path, TEXT);
				if(Assets.exists(lePath))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.set("getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});
		funk.set("directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});
		funk.set("createDirectory", function(folder:String) {
			try {
				FileSystem.createDirectory(SUtil.getStorageDirectory() + folder);
				return true;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("createDirectory: Error trying to create " + folder + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.set("deleteDirectory", function(folder:String) {
			try {
				if(FileSystem.exists(folder))
					FileSystem.deleteDirectory(SUtil.getStorageDirectory() + folder);
					return true;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("deleteDirectory: Error trying to delete " + folder + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.set("parseJson", function(jsonStr:String, varName:String) {
			if (!jsonStr.endsWith('.json')) jsonStr += '.json';
			var json = Paths.modFolders(jsonStr);
			var foundJson:Bool;

			#if sys
			if (FileSystem.exists(json))
				foundJson = true;
			else
			{
				FunkinLua.luaTrace('parseJson: Invalid json file path!', false, false, FlxColor.RED);
				foundJson = false;
				return;
			}
			#else
			if (Assets.exists(json))
				foundJson = true;
			else
			{
				FunkinLua.luaTrace('parseJson: Invalid json file path!', false, false, FlxColor.RED);
				foundJson = false;
				return;
			}
			#end

			if (foundJson) {
				var parsedJson = haxe.Json.parse(File.getContent(json));
				PlayState.instance.variables.set(varName, parsedJson);
			}
		});

		// String tools
		funk.set("stringStartsWith", function(str:String, start:String) {
			return str.startsWith(start);
		});
		funk.set("stringEndsWith", function(str:String, end:String) {
			return str.endsWith(end);
		});
		funk.set("stringSplit", function(str:String, split:String) {
			return str.split(split);
		});
		funk.set("stringTrim", function(str:String) {
			return str.trim();
		});

		// Randomization
		funk.set("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		funk.set("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		funk.set("getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});

		// Android functions
		#if android
		funk.set("vibration", function(period:Int, milliseconds:Int) {
			lime.ui.Haptic.vibrate(period, milliseconds);
		});
		funk.set("toast", function(text:String, time:Int = 0) {
			android.widget.Toast.makeText(text, time);
		});
		#end

		// Other functions
		funk.set("browserLoad", function(url:String) {
			try {
				CoolUtil.browserLoad(url);
				return true;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("browserLoad: Error trying to load " + url + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.set("setClipboard", function(data:String) {
			try {
				openfl.system.System.setClipboard(data);
				return true;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("setClipboard: Error trying to copy " + data + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.set("applicationAlert", function(title:String, description:String) {
			try {
				lime.app.Application.current.window.alert(description, title);
				return true;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("applicationAlert: Error trying to open alert: " + e, false, false, FlxColor.RED);
			}
			return false;
		});
	}
}