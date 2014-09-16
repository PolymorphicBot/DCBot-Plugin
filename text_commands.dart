part of dcbot.plugin;

Storage textCommandStorage;

void initTextCommands() {
  textCommandStorage = new Storage(new File("text_commands.json"));
  textCommandStorage.load();
}

void handleTextCommands(CommandEvent event) {
  String value;
  
  value = textCommandStorage.get("${event.channel} ${event.command}", null);
  
  if (value != null) {
    event.reply("> ${value}", prefix: false);
  } else if ((value = textCommandStorage.get("${event.command}", null)) != null) {
    event.reply("> ${value}", prefix: false);
  }
}