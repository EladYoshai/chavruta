bool isStandalone() => false;
bool isIOS() => false;
bool canPromptInstall() => false;
Future<String> promptInstall() async => 'unsupported';
String notificationStatus() => 'unsupported';
Future<String> enableNotifications() async => 'unsupported';
void setUserId(String uid) {}
