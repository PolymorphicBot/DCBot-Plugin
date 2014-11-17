part of dcbot.plugin;

bool markovEnabled = false;

void handleMessage(data) {
  String network = data['network'];
  String channel = data['target'];
  String user = data['from'];
  String message = data['message'];
  
  String lower = message.toLowerCase();
  
  String firstChar = message.substring(0, 1);
  
  bot.config.then((Map conf) {
    if (conf["prefix"][network].containsKey(channel) &&
        firstChar == conf["prefix"][network][channel]) {
      return;
    } else if (firstChar == conf["prefix"][network]["default"]) {
      return;
    }

    if (lower.contains(new RegExp(r"(thank you|thanks) directcodebot")) ||
    lower.contains(new RegExp(r"directcodebot(\:|\,)? (thanks|thank you)"))) {
      bot.message(network, channel, "${user}: You're Welcome.");
      return;
    }

    if (lower.contains(new RegExp(r"directcodebot(\,|\:?)((\ )(is|is a little|is very|be|very|is super|super|you))? (buggy|sucks|sucky|awful|aweful)", caseSensitive: false))) {
      bot.message(network, channel, "${user}: Sorry for the bad experience. Will you file ama bug report? https://github.com/PolymorphicBot/PolymorphicBot/issues/new");
      return;
    }

    if (markovEnabled && lower.contains("directcodebot")) {
      bot.message(network, channel, markov.reply(message, "DirectCodeBot", user));
    }

    if (markovEnabled) {
      markov.addLine(message);
    }
  });
}
