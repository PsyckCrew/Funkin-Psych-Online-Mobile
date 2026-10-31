package boo.sniro.psychonline;

import android.content.Context;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import org.haxe.extension.Extension;

public class Haptics {

	public static void vibrate(int duration, int amplitude) {
		Vibrator vibrator = (Vibrator) Extension.mainContext.getSystemService(Context.VIBRATOR_SERVICE);
		if (vibrator == null || !vibrator.hasVibrator())
			return;
		if (Build.VERSION.SDK_INT >= 26)
			vibrator.vibrate(VibrationEffect.createOneShot(duration, Math.max(1, Math.min(255, amplitude))));
		else
			vibrator.vibrate(duration);
	}
}
