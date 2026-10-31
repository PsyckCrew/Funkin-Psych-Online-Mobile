package boo.sniro.psychonline;

import android.os.Build;
import android.os.Bundle;
import android.view.KeyEvent;
import android.window.OnBackInvokedCallback;
import android.window.OnBackInvokedDispatcher;
import org.haxe.extension.Extension;
import org.libsdl.app.SDLActivity;

public class BackGesture extends Extension {

	private OnBackInvokedCallback callback;

	private static void sendBack() {
		SDLActivity.onNativeKeyDown(KeyEvent.KEYCODE_BACK);
		SDLActivity.onNativeKeyUp(KeyEvent.KEYCODE_BACK);
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		if (Build.VERSION.SDK_INT >= 33) {
			callback = new OnBackInvokedCallback() {
				@Override
				public void onBackInvoked() {
					sendBack();
				}
			};
			mainActivity.getOnBackInvokedDispatcher().registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT, callback);
		}
	}

	@Override
	public void onDestroy() {
		if (callback != null && Build.VERSION.SDK_INT >= 33)
			mainActivity.getOnBackInvokedDispatcher().unregisterOnBackInvokedCallback(callback);
		callback = null;
	}

	@Override
	public boolean onBackPressed() {
		sendBack();
		return false;
	}
}
