part of dcbot.plugin;

Storage textCommandStorage;

void initTextCommands() {
  textCommandStorage = plugin.getStorage("text_commands", group: "DCBot");
  textCommandStorage.load();
}

void handleTextCommands(CustomCommandEvent event) {
  String value;
  
  value = textCommandStorage.get("${event.command}", null);
  
  if (value != null) {
    event.reply("> ${value}", prefix: false);
  } else if ((value = textCommandStorage.get("${event.network} ${event.channel} ${event.command}", null)) != null) {
    event.reply("> ${value}", prefix: false);
  } else if ((value = textCommandStorage.get("${event.channel} ${event.command}", null)) != null) {
    event.reply("> ${value}", prefix: false);
  }
}
