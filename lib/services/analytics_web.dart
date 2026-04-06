import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void sendGtagEvent(String name, Map<String, Object>? params) {
  try {
    final gtag = globalContext.getProperty('gtag'.toJS);
    if (gtag.isUndefinedOrNull || !gtag.isA<JSFunction>()) return;
    final fn = gtag as JSFunction;
    if (params != null) {
      fn.callAsFunction(null, 'event'.toJS, name.toJS, params.jsify());
    } else {
      fn.callAsFunction(null, 'event'.toJS, name.toJS);
    }
  } catch (_) {}
}
