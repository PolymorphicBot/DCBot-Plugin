library dcbot.plugin;

import "dart:async";

import "dart:math" as Math;

import "dart:io";
import "dart:convert";

import "package:neo/manifest.dart" as manifest;

import "package:irc/client.dart" show Color;
import "package:polymorphic_bot/api.dart";

import "package:quiver/strings.dart";
import "package:github/dates.dart";

import "package:http/http.dart" as http;

import "package:dslink/link.dart";

part "storage.dart";
part "commands.dart";
part "text_commands.dart";
part "messages.dart";
part "gitlab.dart";
part "neo.dart";
part "services.dart";
part "link.dart";

BotConnector bot;

Storage storage;
DateTime startTime;
Plugin plugin;

http.Client httpClient = new http.Client();

String fancyPrefix(String name) {
  return "[${Color.BLUE}${name}${Color.RESET}]";
}

main(args, port) {
  plugin = polymorphic(args, port);
  startTime = new DateTime.now();
  bot = plugin.getBot();

  storage = plugin.getStorage("storage", group: "DCBot");

  storage.load();

  initTextCommands();

  print("[DCBot] Loading Plugin");

  {
    bot.onMessage((event) {
      if (eventBus != null) {
        eventBus.emit("irc.message", {
          "network": event.network,
          "channel": event.target,
          "user": event.from,
          "message": event.message
        });
      }

      storage.incrementInteger("messages_total");
      storage.incrementInteger("${event.network}_messages_total");

      if (event.target.startsWith("#")) {
        storage.incrementInteger("${event.network}_${event.target}_messages_total");
        storage.incrementInteger("${event.network}_${event.target}_user_${event.from}_messages_total");
      }
      handleMessage(event);
    });
  }
  
  var sub = plugin.on("command").listen((event) {
    var data = event;
    var network = data['network'] as String;
    var user = data['from'] as String;
    var target = data['target'] as String;
    var command = data['command'] as String;
    var args = data['args'] as List<String>;
    var message = data['message'] as String;
    var cmdEvent = new CustomCommandEvent(network, command, message, user, target, args);
    
    {
      storage.incrementInteger("${network}_commands_total");
      storage.incrementInteger("${network}_${target}_commands_total");
      storage.incrementInteger("commands_total");
    }
    handleCommand(cmdEvent);
    handleTextCommands(cmdEvent);
  });

  plugin.registerSubscription(sub);
  
  plugin.onShutdown(() {
    print("[DCBot] Unloading Plugin");
    httpClient.close();
    textCommandStorage.destroy();
    storage.destroy();

    for (var timer in countdowns) {
      timer.cancel();
    }
  });

  servicesToken = storage.getString("services_token");
  setupServices();
  setupLink();
}
