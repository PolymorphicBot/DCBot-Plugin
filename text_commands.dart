part of dcbot.plugin;

Storage textCommandStorage;

void initTextCommands() {
  textCommandStorage = bot.createStorage("DCBot", "text_commands");
  textCommandStorage.load();
}

void handleTextCommands(CustomCommandEvent event) {
  String value;
  
  value = textCommandStorage.get("${event.channel} ${event.command}", null);
  
  if (value != null) {
    event.reply("> ${value}", prefix: false);
  } else if ((value = textCommandStorage.get("${event.command}", null)) != null) {
    event.reply("> ${value}", prefix: false);
  }
}