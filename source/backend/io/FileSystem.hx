package backend.io;

#if mobile
import haxe.io.Path;
#end

class FileSystem
{
	#if !mobile
	public static inline function exists(path:String):Bool
		return sys.FileSystem.exists(path);

	public static inline function isDirectory(path:String):Bool
		return sys.FileSystem.isDirectory(path);

	public static inline function readDirectory(path:String):Array<String>
		return sys.FileSystem.readDirectory(path);
	#else
	public static function exists(path:String):Bool
	{
		if (sys.FileSystem.exists(path))
			return true;
		var rel = AssetIndex.relative(path);
		return AssetIndex.hasFile(rel) || AssetIndex.hasDirectory(rel);
	}

	public static function isDirectory(path:String):Bool
	{
		if (sys.FileSystem.exists(path))
			return sys.FileSystem.isDirectory(path);
		return AssetIndex.hasDirectory(AssetIndex.relative(path));
	}

	public static function readDirectory(path:String):Array<String>
	{
		var onDisk = sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path);
		var packed = AssetIndex.children(AssetIndex.relative(path));
		if (!onDisk && packed == null)
			return sys.FileSystem.readDirectory(path);

		var result = onDisk ? sys.FileSystem.readDirectory(path) : [];
		if (packed != null)
			for (name in packed)
				if (!result.contains(name))
					result.push(name);
		return result;
	}
	#end

	public static inline function createDirectory(path:String):Void
		sys.FileSystem.createDirectory(path);

	public static inline function deleteFile(path:String):Void
		sys.FileSystem.deleteFile(path);

	public static inline function deleteDirectory(path:String):Void
		sys.FileSystem.deleteDirectory(path);

	public static inline function rename(path:String, newPath:String):Void
		sys.FileSystem.rename(path, newPath);

	public static inline function stat(path:String):sys.FileStat
		return sys.FileSystem.stat(path);

	public static inline function fullPath(relPath:String):String
		return sys.FileSystem.fullPath(relPath);

	public static inline function absolutePath(relPath:String):String
		return sys.FileSystem.absolutePath(relPath);
}

#if mobile
class AssetIndex
{
	static var files:Map<String, String>;
	static var dirs:Map<String, Array<String>>;
	static var libraryCount:Int = -1;

	public static function relative(path:String):String
	{
		var p = Path.normalize(path);
		var cwd = Path.normalize(Sys.getCwd());
		if (cwd.length > 0 && p.startsWith(cwd))
			p = p.substr(cwd.length);
		while (p.startsWith('./'))
			p = p.substr(2);
		while (p.startsWith('/'))
			p = p.substr(1);
		return Path.removeTrailingSlashes(p);
	}

	public static function hasFile(rel:String):Bool
	{
		ensure();
		return files.exists(rel);
	}

	public static function hasDirectory(rel:String):Bool
	{
		ensure();
		return dirs.exists(rel);
	}

	public static function children(rel:String):Array<String>
	{
		ensure();
		var list = dirs.get(rel);
		return list == null ? null : list.copy();
	}

	public static function packedPath(path:String):String
	{
		ensure();
		return files.get(relative(path));
	}

	static function ensure()
	{
		var libraries = @:privateAccess lime.utils.Assets.libraries;
		var count = Lambda.count(libraries);
		if (files != null && count == libraryCount)
			return;
		libraryCount = count;
		files = [];
		dirs = [];
		for (library in libraries)
		{
			var paths:Map<String, String> = @:privateAccess library.paths;
			for (limePath in paths)
				add(limePath);
		}
	}

	static function add(limePath:String)
	{
		var rel = relative(limePath);
		if (rel.length == 0 || files.exists(rel))
			return;
		files.set(rel, limePath);

		var child = Path.withoutDirectory(rel);
		var dir = Path.directory(rel);
		while (true)
		{
			var list = dirs.get(dir);
			var isNew = list == null;
			if (isNew)
				dirs.set(dir, list = []);
			if (!list.contains(child))
				list.push(child);
			if (!isNew || dir.length == 0)
				break;
			child = Path.withoutDirectory(dir);
			dir = Path.directory(dir);
		}
	}
}
#end
