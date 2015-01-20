part of dcbot.plugin;

Storage textCommandStorage;

void initTextCommands() {
  textCommandStorage = plugin.getStorage("text_commands", group: "DCBot");
  textCommandStorage.load();
}

void handleTextCommands(CustomCommandEvent event) {
  String value;
  
  value = textCommandStorage.getString("${event.command}");
  
  if (value != null) {
    event.reply("> ${value}", prefix: false);
  } else if ((value = textCommandStorage.getString("${event.network} ${event.channel} ${event.command}")) != null) {
    event.reply("> ${value}", prefix: false);
  } else if ((value = textCommandStorage.getString("${event.channel} ${event.command}")) != null) {
    event.reply("> ${value}", prefix: false);
  }
}
