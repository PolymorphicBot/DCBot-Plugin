part of dcbot.plugin;

class RegExSupport {
  static void handle(data) {
    String network = data['network'];
    String target = data['target'];
    String message = data['message'];
    String user = data['from'];
    
    void reply(String message, {bool prefix: true, String prefixContent: "Regular Expression"}) {
      bot.message(network, target, (prefix ? "[${Color.BLUE}${prefixContent}${Color.RESET}] " : "") + message);
    }
    
    if (message.startsWith("s/") && message.length > 3) {
      var msg = message.substring(2); // skip "s/"
      var first = true;
      var escaped = true;
      var reverse = false;

      var now = new DateTime.now();

      if (now.month == DateTime.APRIL && now.day == 1) {
        reverse = true;
        return;
      }

      if (msg.endsWith("/")) {
        msg = msg.substring(0, msg.length - 1);
      } else if (msg.endsWith("/g")) {
        msg = msg.substring(0, msg.length - 2);
        first = false;
      } else if (msg.endsWith("/n")) {
        msg = msg.substring(0, msg.length - 2);
        escaped = false;
      }

      var index = msg.indexOf("/");
      var expr = msg.substring(0, index);
      var replacement = msg.substring(index + 1, msg.length);

      String aExpr;
      if (escaped) {
        aExpr = escapeRegex(expr);
      } else {
        aExpr = expr;
      }
      if (reverse) replacement = new String.fromCharCodes(replacement.codeUnits.reversed);

      var regex = new RegExp(aExpr);

      var events = Buffer.get("${network}${target}");
      for (BufferEntry entry in events) {
        if (regex.hasMatch(entry.message)) {
          var dat_msg = entry.message;
          var new_msg = first ? dat_msg.replaceFirst(regex, replacement) : dat_msg.replaceAll(regex, replacement);
          var e = new BufferEntry(entry.network, entry.target, entry.user, new_msg);
          reply(e.user + ": " + e.message);
          Buffer.handle(e.toData());
          return;
        }
      }
      reply("ERROR: No Match Found for expression '${expr}'");
    }
  }
}