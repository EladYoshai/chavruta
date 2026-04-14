import 'dart:js_interop';
import 'dart:js_interop_unsafe';

JSObject get _window => globalContext;

bool isStandalone() {
  try {
    final fn = _window.getProperty('chavrutaIsStandalone'.toJS);
    if (fn.isUndefinedOrNull || !fn.isA<JSFunction>()) return false;
    final res = (fn as JSFunction).callAsFunction(null);
    return (res as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

bool isIOS() {
  try {
    final fn = _window.getProperty('chavrutaIsIOS'.toJS);
    if (fn.isUndefinedOrNull || !fn.isA<JSFunction>()) return false;
    final res = (fn as JSFunction).callAsFunction(null);
    return (res as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

bool canPromptInstall() {
  try {
    final fn = _window.getProperty('chavrutaCanInstall'.toJS);
    if (fn.isUndefinedOrNull || !fn.isA<JSFunction>()) return false;
    final res = (fn as JSFunction).callAsFunction(null);
    return (res as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

Future<String> promptInstall() async {
  try {
    final fn = _window.getProperty('chavrutaPromptInstall'.toJS);
    if (fn.isUndefinedOrNull || !fn.isA<JSFunction>()) return 'unavailable';
    final res = (fn as JSFunction).callAsFunction(null);
    if (res == null) return 'error';
    final promise = res as JSPromise;
    final out = await promise.toDart;
    return (out as JSString?)?.toDart ?? 'error';
  } catch (_) {
    return 'error';
  }
}

String notificationStatus() {
  try {
    final fn = _window.getProperty('chavrutaNotificationStatus'.toJS);
    if (fn.isUndefinedOrNull || !fn.isA<JSFunction>()) return 'unsupported';
    final res = (fn as JSFunction).callAsFunction(null);
    return (res as JSString?)?.toDart ?? 'unsupported';
  } catch (_) {
    return 'unsupported';
  }
}

Future<String> enableNotifications() async {
  try {
    final fn = _window.getProperty('chavrutaEnableNotifications'.toJS);
    if (fn.isUndefinedOrNull || !fn.isA<JSFunction>()) return 'unsupported';
    final res = (fn as JSFunction).callAsFunction(null);
    if (res == null) return 'error';
    final promise = res as JSPromise;
    final out = await promise.toDart;
    return (out as JSString?)?.toDart ?? 'error';
  } catch (_) {
    return 'error';
  }
}

void setUserId(String uid) {
  try {
    final fn = _window.getProperty('chavrutaSetUserId'.toJS);
    if (fn.isUndefinedOrNull || !fn.isA<JSFunction>()) return;
    (fn as JSFunction).callAsFunction(null, uid.toJS);
  } catch (_) {}
}
