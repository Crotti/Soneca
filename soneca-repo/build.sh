#!/usr/bin/env bash
# Soneca - gera o APK a partir do index.html do repositorio
set -ex
F=index.html
test -f "$F"
BN="${BITRISE_BUILD_NUMBER:-$(( ${GITHUB_RUN_NUMBER:-1} + 6 ))}"
VER="1.${BN}"
OUT="${OUT_DIR:-dist}"
CAP=6.2.0
java -version
mkdir -p www scripts patch "$OUT"
echo "DIAG src=$F md5=$(md5sum "$F" | cut -d' ' -f1) bytes=$(wc -c < "$F") ver=$VER"
cp "$F" patch/src.html
cat > patch/pre.html <<'PRE_EOF'
<script>
(function(){function box(t){try{var d=document.getElementById('errbox');if(!d){d=document.createElement('div');d.id='errbox';d.style.cssText='position:fixed;left:8px;right:8px;top:8px;z-index:99999;background:#b3261e;color:#fff;font:12px/1.4 monospace;padding:8px 10px;border-radius:10px;white-space:pre-wrap;max-height:45vh;overflow:auto';d.onclick=function(){d.parentNode&&d.parentNode.removeChild(d)};(document.body||document.documentElement).appendChild(d)}d.textContent+=t+String.fromCharCode(10)}catch(e){}}
window.onerror=function(m,u,l,c){box('Erro: '+m+' (linha '+l+':'+c+')');return false};
window.addEventListener('unhandledrejection',function(e){var r=e&&e.reason;box('Falha: '+(r&&r.message||r))});
window.__box=box;
if(!String.prototype.padStart){String.prototype.padStart=function(n,s){s=String(s===undefined?' ':s);var t=String(this);while(t.length<n)t=s+t;return t.slice(-n===0?0:t.length-n)}}
})();
</script>
PRE_EOF
cat > patch/patch.py <<'PY_EOF'
import sys,os,subprocess
src,out,ver=sys.argv[1:4]
h=open(src,encoding='utf-8').read()
pre=open('pre.html',encoding='utf-8').read()
assert h.count('<script>')==1,'script count'
h=h.replace('<script>',pre+'<script>',1)
h=h.replace('s.setPointerCapture(e.pointerId);','try{s.setPointerCapture(e.pointerId)}catch(x){}')
pill='<h1>Soneca <span id="ver" style="font-size:11px;font-weight:600;vertical-align:middle;padding:2px 8px;border-radius:99px;background:var(--cs);color:var(--ac);letter-spacing:.2px">v'+ver+'</span></h1>'
assert '<h1>Soneca</h1>' in h,'h1'
h=h.replace('<h1>Soneca</h1>',pill,1)
i=h.rfind('<script>');j=h.rfind('</script>')
js=h[i+8:j]
open('main.js','w',encoding='utf-8').write(js)
esb=os.environ.get('ESB','npx --yes esbuild@0.21.5')
r=subprocess.run(esb.split()+['main.js','--target=es2015','--charset=utf8','--outfile=main.es5.js','--log-level=warning'],capture_output=True,text=True)
print('esbuild rc',r.returncode,r.stderr[:300])
if r.returncode==0 and os.path.exists('main.es5.js'):
    js=open('main.es5.js',encoding='utf-8').read()
h=h[:i+8]+'\n'+js+h[j:]
open(out,'w',encoding='utf-8').write(h)
print('OUT',len(h.encode()),'optchain',h.count('?.'))
PY_EOF
(cd patch && python3 patch.py src.html ../www/index.html "$VER")
echo "DIAG www bytes=$(wc -c < www/index.html) dsv=$(grep -c dsv www/index.html || true) dys=$(grep -c dys www/index.html || true) ver=$(grep -o "v${VER}</span>" www/index.html | head -1 || true)"
mkdir -p ~/.android
base64 -d > ~/.android/debug.keystore <<'KS_EOF'
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
KS_EOF
if keytool -list -keystore ~/.android/debug.keystore -storepass android > /tmp/kl.txt 2>&1; then grep -i fingerprint /tmp/kl.txt; else echo KEYSTORE_INVALID; rm -f ~/.android/debug.keystore; fi
cat > package.json <<EOF
{"name":"soneca","version":"1.0.0","private":true,"dependencies":{"@capacitor/android":"^$CAP","@capacitor/core":"^$CAP"},"devDependencies":{"@capacitor/cli":"^$CAP"}}
EOF
cat > capacitor.config.json <<'EOF'
{"appId":"com.soneca.app","appName":"Soneca","webDir":"www","android":{"backgroundColor":"#0a0818"}}
EOF
python3 - <<'PY'
import wave,math,struct
def gen(name,fn):
    sr=16000;fb=bytearray()
    for i in range(sr*12):
        fb+=struct.pack('<h',int(max(-1,min(1,fn(i/sr)))*32767))
    w=wave.open('scripts/'+name+'.wav','wb');w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes(bytes(fb));w.close()
def amanhecer(t):
    ct=t%3;s=0
    for k,f in enumerate([523.25,659.25,783.99,1046.5]):
        d=ct-k*.4
        if d>=0:s+=math.sin(2*math.pi*f*t)*math.exp(-d*1.6)*(1-math.exp(-d*60))
    return s*.5
def sino(t):
    d=t%4;s=0
    for f,a in [(880,1),(1320,.5),(1760,.3)]:
        s+=a*math.sin(2*math.pi*f*t)*math.exp(-d*1.3)*(1-math.exp(-d*80))
    return s*.45
def pulso(t):
    d=t%1;s=0
    for k in range(3):
        x=d-k*.25
        if 0<=x<.15:s+=math.sin(2*math.pi*880*t)*math.sin(math.pi*x/.15)
    return s*.5
gen('amanhecer',amanhecer);gen('sino',sino);gen('pulso',pulso)
PY
cat > scripts/perms.xml <<'EOF'
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
EOF
cat > scripts/app.xml <<'EOF'
    <service android:name=".AlarmService" android:exported="false" android:foregroundServiceType="mediaPlayback"/>
    <receiver android:name=".AlarmReceiver" android:exported="false"/>
EOF
cat > scripts/MainActivity.java <<'EOF'
package com.soneca.app;

import android.os.Build;
import android.os.Bundle;
import android.view.WindowManager;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
  @Override
  public void onCreate(Bundle savedInstanceState) {
    registerPlugin(AlarmPlugin.class);
    super.onCreate(savedInstanceState);
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    if (Build.VERSION.SDK_INT >= 27) {
      setShowWhenLocked(true);
      setTurnScreenOn(true);
    }
    if (Build.VERSION.SDK_INT >= 33) {
      requestPermissions(new String[] {"android.permission.POST_NOTIFICATIONS"}, 1);
    }
  }
}
EOF
cat > scripts/AlarmReceiver.java <<'EOF'
package com.soneca.app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

public class AlarmReceiver extends BroadcastReceiver {
  @Override
  public void onReceive(Context c, Intent i) {
    Intent s = new Intent(c, AlarmService.class)
        .putExtra("snd", i.getStringExtra("snd"))
        .putExtra("vol", i.getIntExtra("vol", 100));
    if (Build.VERSION.SDK_INT >= 26) c.startForegroundService(s);
    else c.startService(s);
  }
}
EOF
cat > scripts/AlarmPlugin.java <<'EOF'
package com.soneca.app;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "Alarm")
public class AlarmPlugin extends Plugin {
  @PluginMethod
  public void schedule(PluginCall c) {
    try {
      Context x = getContext();
      Intent in = new Intent(x, AlarmReceiver.class)
          .putExtra("snd", c.getString("snd", "amanhecer"))
          .putExtra("vol", c.getInt("vol", 100));
      PendingIntent pi = PendingIntent.getBroadcast(x, 7, in, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
      PendingIntent show = PendingIntent.getActivity(x, 8, new Intent(x, MainActivity.class), PendingIntent.FLAG_IMMUTABLE);
      AlarmManager am = (AlarmManager) x.getSystemService(Context.ALARM_SERVICE);
      am.setAlarmClock(new AlarmManager.AlarmClockInfo(c.getDouble("at").longValue(), show), pi);
      c.resolve();
    } catch (Exception e) {
      c.reject(String.valueOf(e.getMessage()));
    }
  }

  @PluginMethod
  public void cancel(PluginCall c) {
    Context x = getContext();
    PendingIntent pi = PendingIntent.getBroadcast(x, 7, new Intent(x, AlarmReceiver.class), PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_NO_CREATE);
    if (pi != null) ((AlarmManager) x.getSystemService(Context.ALARM_SERVICE)).cancel(pi);
    c.resolve();
  }

  @PluginMethod
  public void ring(PluginCall c) {
    Context x = getContext();
    Intent s = new Intent(x, AlarmService.class)
        .putExtra("snd", c.getString("snd", "amanhecer"))
        .putExtra("vol", c.getInt("vol", 100))
        .putExtra("pv", c.getBoolean("pv", false));
    if (Build.VERSION.SDK_INT >= 26) x.startForegroundService(s);
    else x.startService(s);
    c.resolve();
  }

  @PluginMethod
  public void stop(PluginCall c) {
    Context x = getContext();
    x.stopService(new Intent(x, AlarmService.class));
    c.resolve();
  }

  @PluginMethod
  public void status(PluginCall c) {
    JSObject r = new JSObject();
    r.put("ringing", AlarmService.ringing);
    c.resolve(r);
  }
}
EOF
cat > scripts/AlarmService.java <<'EOF'
package com.soneca.app;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.PowerManager;
import android.os.VibrationEffect;
import android.os.Vibrator;

public class AlarmService extends Service {
  static volatile boolean ringing = false;
  MediaPlayer mp;
  AudioManager am;
  PowerManager.WakeLock wl;
  Vibrator vb;
  Handler h = new Handler(Looper.getMainLooper());
  int old = -1;
  float g = 0.05f;

  @Override
  public IBinder onBind(Intent i) {
    return null;
  }

  @Override
  public int onStartCommand(Intent in, int flags, int id) {
    String snd = in != null && in.getStringExtra("snd") != null ? in.getStringExtra("snd") : "amanhecer";
    int pct = in != null ? in.getIntExtra("vol", 100) : 100;
    final boolean pv = in != null && in.getBooleanExtra("pv", false);
    NotificationManager nm = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
    if (Build.VERSION.SDK_INT >= 26) {
      NotificationChannel ch = new NotificationChannel("alarme", "Alarme", NotificationManager.IMPORTANCE_HIGH);
      ch.setSound(null, null);
      nm.createNotificationChannel(ch);
    }
    PendingIntent pi = PendingIntent.getActivity(this, 0,
        new Intent(this, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
    Notification.Builder b = Build.VERSION.SDK_INT >= 26 ? new Notification.Builder(this, "alarme") : new Notification.Builder(this);
    b.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
        .setContentTitle("Soneca")
        .setContentText(pv ? "Testando o som" : "Hora de acordar")
        .setCategory(Notification.CATEGORY_ALARM)
        .setContentIntent(pi)
        .setFullScreenIntent(pi, true)
        .setOngoing(true);
    if (Build.VERSION.SDK_INT >= 29) startForeground(1, b.build(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK);
    else startForeground(1, b.build());
    if (ringing && !pv) return START_NOT_STICKY;
    release();
    ringing = !pv;
    am = (AudioManager) getSystemService(AUDIO_SERVICE);
    old = am.getStreamVolume(AudioManager.STREAM_ALARM);
    try {
      int mx = am.getStreamMaxVolume(AudioManager.STREAM_ALARM);
      am.setStreamVolume(AudioManager.STREAM_ALARM, Math.max(1, Math.round(mx * pct / 100f)), 0);
    } catch (Exception e) {
    }
    int rid = getResources().getIdentifier(snd, "raw", getPackageName());
    if (rid == 0) rid = getResources().getIdentifier("amanhecer", "raw", getPackageName());
    AudioAttributes aa = new AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build();
    mp = MediaPlayer.create(this, rid, aa, am.generateAudioSessionId());
    mp.setLooping(true);
    g = 0.05f;
    mp.setVolume(g, g);
    mp.start();
    final float step = 0.95f / ((pv ? 3 : 45) * 5);
    h.post(new Runnable() {
      @Override
      public void run() {
        if (mp == null) return;
        g = Math.min(1f, g + step);
        mp.setVolume(g, g);
        if (g < 1f) h.postDelayed(this, 200);
      }
    });
    vb = (Vibrator) getSystemService(VIBRATOR_SERVICE);
    long[] pat = {0, 700, 500};
    if (Build.VERSION.SDK_INT >= 26) vb.vibrate(VibrationEffect.createWaveform(pat, 0));
    else vb.vibrate(pat, 0);
    wl = ((PowerManager) getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "soneca:alarme");
    wl.acquire(11 * 60 * 1000L);
    h.postDelayed(new Runnable() {
      @Override
      public void run() {
        stopSelf();
      }
    }, pv ? 6000 : 600000);
    return START_NOT_STICKY;
  }

  void release() {
    h.removeCallbacksAndMessages(null);
    if (mp != null) {
      try {
        mp.stop();
      } catch (Exception e) {
      }
      mp.release();
      mp = null;
    }
    if (vb != null) vb.cancel();
    if (wl != null && wl.isHeld()) wl.release();
    if (am != null && old >= 0) {
      try {
        am.setStreamVolume(AudioManager.STREAM_ALARM, old, 0);
      } catch (Exception e) {
      }
    }
    old = -1;
  }

  @Override
  public void onDestroy() {
    release();
    ringing = false;
    super.onDestroy();
  }
}
EOF
npm install --no-audit --no-fund
npx cap add android
M=android/app/src/main
mkdir -p $M/res/raw
cp scripts/amanhecer.wav scripts/sino.wav scripts/pulso.wav $M/res/raw/
grep -q RECORD_AUDIO $M/AndroidManifest.xml || sed -i '/<\/manifest>/e cat scripts/perms.xml' $M/AndroidManifest.xml
grep -q AlarmService $M/AndroidManifest.xml || sed -i '/<\/application>/e cat scripts/app.xml' $M/AndroidManifest.xml
cp scripts/*.java $M/java/com/soneca/app/
sed -i "s/versionCode 1/versionCode ${BN}/; s/versionName \"1.0\"/versionName \"${VER}\"/" android/app/build.gradle
grep -n "versionCode\|versionName" android/app/build.gradle
npx cap sync android
cd android
./gradlew assembleDebug --no-daemon --console=plain
cd ..
echo "DIAG apk_ver=$(unzip -p android/app/build/outputs/apk/debug/app-debug.apk assets/public/index.html | grep -o "v${VER}</span>" | head -1 || true) apk_dsv=$(unzip -p android/app/build/outputs/apk/debug/app-debug.apk assets/public/index.html | grep -c dsv || true)"
cp android/app/build/outputs/apk/debug/app-debug.apk "$OUT/soneca.apk"
echo "APK pronto: $OUT/soneca.apk (versao $VER)"
