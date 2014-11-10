part of dcbot.plugin;

void handleMessage(data) {
  String network = data['network'];
  String channel = data['target'];
  String user = data['from'];
  String message = data['message'];
  
  String lower = message.toLowerCase();
  
  if (lower.contains(new RegExp(r"(thank you|thanks) directcodebot")) ||
      lower.contains(new RegExp(r"directcodebot(\:|\,)? (thanks|thank you)"))) {
    bot.message(network, channel, "${user}: You're Welcome.");
  }
  
  if (lower.contains(new RegExp(r"directcodebot(\,|\:?)((\ )(is|is a little|is very|be|very|is super|super|you))? (buggy|sucks|sucky|awful|aweful)", caseSensitive: false))) {
    bot.message(network, channel, "${user}: Sorry for the bad experience. Will you file a bug report? https://github.com/PolymorphicBot/PolymorphicBot/issues/new");
  }
}
