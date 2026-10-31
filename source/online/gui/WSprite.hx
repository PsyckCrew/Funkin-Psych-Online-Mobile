package online.gui;

import openfl.Lib;

class WSprite extends Sprite {
	var _windowWidth:Float = 0;
	var _windowHeight:Float = 0;
    
    public function new() {
        super();

		_windowWidth = Util.screenWidth;
		_windowHeight = Util.screenHeight;

        #if !mobile
        Lib.application.window.onResize.add((w, h) -> {
			final scale = Math.min(w / _windowWidth, h / _windowHeight);
			scaleX = scale;
			scaleY = scale;
			x = w / 2 - _windowWidth * scale / 2;
			y = h / 2 - _windowHeight * scale / 2;
        });
        #end
    }
}