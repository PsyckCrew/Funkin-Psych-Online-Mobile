package backend.io;

import haxe.io.Bytes;
import sys.io.FileInput;
import sys.io.FileOutput;

class File
{
	#if !mobile
	public static inline function getContent(path:String):String
		return sys.io.File.getContent(path);

	public static inline function getBytes(path:String):Bytes
		return sys.io.File.getBytes(path);
	#else
	public static function getContent(path:String):String
	{
		var packed = packed(path);
		return packed != null ? packed.toString() : sys.io.File.getContent(path);
	}

	public static function getBytes(path:String):Bytes
	{
		var packed = packed(path);
		return packed != null ? packed : sys.io.File.getBytes(path);
	}

	static function packed(path:String):Bytes
	{
		if (sys.FileSystem.exists(path))
			return null;
		var limePath = FileSystem.AssetIndex.packedPath(path);
		return limePath == null ? null : lime.utils.Bytes.fromFile(limePath);
	}
	#end

	public static inline function saveContent(path:String, content:String):Void
		sys.io.File.saveContent(path, content);

	public static inline function saveBytes(path:String, bytes:Bytes):Void
		sys.io.File.saveBytes(path, bytes);

	public static inline function read(path:String, binary:Bool = true):FileInput
		return sys.io.File.read(path, binary);

	public static inline function write(path:String, binary:Bool = true):FileOutput
		return sys.io.File.write(path, binary);

	public static inline function append(path:String, binary:Bool = true):FileOutput
		return sys.io.File.append(path, binary);

	public static inline function update(path:String, binary:Bool = true):FileOutput
		return sys.io.File.update(path, binary);

	public static inline function copy(srcPath:String, dstPath:String):Void
		sys.io.File.copy(srcPath, dstPath);
}
