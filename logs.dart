part of dcbot.plugin;

void handleLogging(var event) {
  print("[${new DateTime.now().millisecondsSinceEpoch}] <${event['from']}> ${event['message']}");
}
