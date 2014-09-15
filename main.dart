library dcbot.plugin;

import "dart:async";
import "dart:io";
import "dart:convert";

import "package:irc/irc.dart" show Color;
import "package:polymorphic_bot/api.dart";

import "package:quiver/strings.dart";
import "package:quiver/pattern.dart";

import "package:github/dates.dart";

import "package:http/http.dart" as http;

import "package:route/server.dart";
import "package:http_server/http_server.dart";

part "storage.dart";
part "slack.dart";
part "server.dart";
part "buffer.dart";
part "regex.dart";
part "commands.dart";

APIConnector bot;

Storage storage;

http.Client httpClient = new http.Client();

String fancyPrefix(String name) {
  return "[${Color.BLUE}${name}${Color.RESET}]";
}

void main(List<String> args, port) {
  bot = new APIConnector(port);

  storage = new Storage(new File("storage.json"));
  
  storage.load();
  
  print("[DirectCode] Loading Plugin");

  bot.handleEvent((event) {
    switch (event['event']) {
      case "message":
        RegExSupport.handle(event);
        
        Buffer.handle(event);
        
        var totalCount = storage.get("messages_total", 0);
        totalCount++;
        storage.set("messages_total", totalCount);
        
        var netTotalCount = storage.get("${event['network']}_messages_total", 0);
        netTotalCount++;
        storage.set("${event['network']}_messages_total", netTotalCount);
                
        if (event['target'].startsWith("#")) {
          var chanTotal = storage.get("${event['network']}_${event['target']}_messages_total", 0);
          chanTotal++;
          storage.set("${event['network']}_${event['target']}_messages_total", chanTotal);
          
          var chanUserTotal = storage.get("${event['network']}_${event['target']}_user_${event['from']}_messages_total", 0);
          chanUserTotal++;
          storage.set("${event['network']}_${event['target']}_user_${event['from']}_messages_total", chanUserTotal);
        }
        break;
      case "command":
        var data = event;
        var network = data['network'] as String;
        var user = data['from'] as String;
        var target = data['target'] as String;
        var command = data['command'] as String;
        var args = data['args'] as List<String>;
        var message = data['message'] as String;
        handleCommand(new CommandEvent(network, command, message, user, target, args));
        break;
      case "shutdown":
        server.close(force: true);
        break;
    }
  });
  
  setupServer().then((_) {
    print("[DCBot] Server Started");
    setupSlack();
    print("[DCBot] Slack Integration Setup");
  });
}

