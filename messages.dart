part of dcbot.plugin;

Math.Random random = new Math.Random();

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
    lower.contains(new RegExp(r"directcodebot(\:|\,)? (thanks|thank you|thank ya|thx|thnx)"))) {
      bot.message(network, channel, "${user}: You're Welcome.");
      return;
    }

    if (lower.contains(new RegExp(r"directcodebot(\,|\:?)((\ )(is|is a little|is very|be|very|is super|super|you))? (buggy|sucks|sucky|awful|aweful)", caseSensitive: false))) {
      bot.message(network, channel, "${user}: Sorry for the bad experience. Will you file a bug report? https://github.com/PolymorphicBot/PolymorphicBot/issues/new");
      return;
    }

    if (lower.contains(new RegExp(r"don\'?t make me get(?: out)? the whip"))) {
      bot.message(network, channel, "I like whips.");
    }

    {
      var chance = random.nextInt(20);

      if ((lower.contains("ed") || lower.contains("ing")) && (chance == 10)) {
        bot.message(network, channel, "${message.replaceAll("ed", "forked").replaceAll("ing", "forking")}");
      }
    }

    {
      var chance = random.nextInt(20);

      if ((lower.contains("kaendfinger")) && (chance == 5)) {
        bot.message(network, channel, "did you mean kaendfork?");
      }
    }

    if (markovEnabled && lower.contains("directcodebot")) {
      bot.message(network, channel, markov.reply(message, "DirectCodeBot", user));
    }

    if (markovEnabled) {
      markov.addLine(message);
    }
  });
}
