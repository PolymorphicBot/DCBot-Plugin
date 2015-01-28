part of dcbot.plugin;

Math.Random random = new Math.Random();

void handleMessage(MessageEvent event) {
  String network = event.network;
  String channel = event.target;
  String user = event.from;
  String message = event.message;
  
  String lower = message.toLowerCase();
  
  String firstChar = message.substring(0, 1);
  
  bot.config.then((Map conf) {
    if (conf["prefixes"][network].containsKey(channel) &&
        firstChar == conf["prefixes"][network][channel]) {
      return;
    } else if (firstChar == conf["prefixes"][network]["default"]) {
      return;
    }

    if (lower.contains(new RegExp(r"(thank you|thanks) directcodebot")) ||
    lower.contains(new RegExp(r"directcodebot(\:|\,)? (thanks|thank you|thank ya|thx|thnx)"))) {
      bot.sendMessage(network, channel, "${user}: You're Welcome.");
      return;
    }

    if (lower.contains(new RegExp(r"directcodebot is (sexy|a sexy mofo|very smart|smart|swaggy|a swagster|my brah|my homie)", caseSensitive: false)))
    {
      bot.sendMessage(network, channel, "${user}: Thanks! You are too :)");
      return;
    }

    if (lower.contains(new RegExp(r"directcodebot(\,|\:?)((\ )(is|is a little|is very|be|very|is super|super|you))? (buggy|sucks|sucky|awful|aweful|smells|smelly|stinky)", caseSensitive: false))) {
      bot.sendMessage(network, channel, "${user}: Sorry for the bad experience. Will you file a bug report? https://github.com/PolymorphicBot/PolymorphicBot/issues/new");
      return;
    }
  });
}
