library dcbot.plugin;

import "dart:async";
import "dart:io";
import "dart:convert";

import "package:irc/irc.dart" show Color;
import "package:polymorphic_bot/api.dart";

import "package:quiver/strings.dart";

import "package:github/dates.dart";

import "package:http/http.dart" as http;

import "package:route/server.dart";
import "package:http_server/http_server.dart";

part "storage.dart";
part "slack.dart";
part "server.dart";
part "commands.dart";
part "text_commands.dart";
part "apidocs.dart";
part "messages.dart";

BotConnector bot;

Storage storage;

http.Client httpClient = new http.Client();

String fancyPrefix(String name) {
  return "[${Color.BLUE}${name}${Color.RESET}]";
}

EventManager eventManager;

void main(List<String> args, port) {
  bot = new BotConnector(port);
  
  storage = bot.createStorage("DCBot", "storage");
  
  storage.load();
  
  initTextCommands();
  
  APIDocs.init();
  
  print("[DCBot] Loading Plugin");
  
  eventManager = bot.createEventManager();
  
  eventManager.on("message").listen((event) {
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
    handleMessage(event);
  });
  
  eventManager.on("command").listen((event) {
    var data = event;
    var network = data['network'] as String;
    var user = data['from'] as String;
    var target = data['target'] as String;
    var command = data['command'] as String;
    var args = data['args'] as List<String>;
    var message = data['message'] as String;
    var cmdEvent = new CustomCommandEvent(network, command, message, user, target, args);
    handleCommand(cmdEvent);
    handleTextCommands(cmdEvent);
  });
  
  eventManager.on("shutdown").listen((event) {
    server.close(force: true);
    httpClient.close();
    textCommandStorage.destroy();
    storage.destroy();
  });
  
  setupServer().then((_) {
    print("[DCBot] Server Started");
    setupSlack();
    print("[DCBot] Slack Integration Setup");
  });
}

