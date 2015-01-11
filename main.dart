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

void main(List<String> args, Plugin myPlugin) {
  plugin = myPlugin;
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

      var totalCount = storage.get("messages_total", 0);
      totalCount++;
      storage.set("messages_total", totalCount);

      var netTotalCount = storage.get("${event.network}_messages_total", 0);
      netTotalCount++;
      storage.set("${event.network}_messages_total", netTotalCount);

      if (event.target.startsWith("#")) {
        var chanTotal = storage.get("${event.network}_${event.target}_messages_total", 0);
        chanTotal++;
        storage.set("${event.network}_${event.target}_messages_total", chanTotal);

        var chanUserTotal = storage.get("${event.network}_${event.target}_user_${event.from}_messages_total", 0);
        chanUserTotal++;
        storage.set("${event.network}_${event.target}_user_${event.from}_messages_total", chanUserTotal);
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
      var networkCommandsTotal = storage.get("${network}_commands_total", 0);
      var channelCommandsTotal = storage.get("${network}_${target}_commands_total", 0);
      var commandsTotal = storage.get("commands_total", 0);
      networkCommandsTotal++;
      channelCommandsTotal++;
      commandsTotal++;
      storage.set("${network}_commands_total", networkCommandsTotal);
      storage.set("${network}_${target}_commands_total", channelCommandsTotal);
      storage.set("commands_total", commandsTotal);
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

  servicesToken = storage.get("services_token");
  setupServices();
  setupLink();
}
