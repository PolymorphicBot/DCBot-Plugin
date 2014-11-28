library dcbot.plugin;

import "dart:async";

import "dart:math" as Math;

import "dart:io";
import "dart:convert";

import "package:neo/manifest.dart" as manifest;

import "package:irc/irc.dart" show Color;
import "package:polymorphic_bot/api.dart";

import "package:quiver/strings.dart";

import "package:github/dates.dart";

import "package:http/http.dart" as http;

import "markov.dart";

import "package:route/server.dart";
import "package:http_server/http_server.dart";

part "storage.dart";
part "server.dart";
part "commands.dart";
part "text_commands.dart";
part "apidocs.dart";
part "messages.dart";
part "gitlab.dart";
part "neo.dart";
part "logs.dart";

BotConnector bot;

Storage storage;
MarkovChain markov;
DateTime startTime;
Timer markovTimer;

http.Client httpClient = new http.Client();

String fancyPrefix(String name) {
  return "[${Color.BLUE}${name}${Color.RESET}]";
}

EventManager eventManager;

void main(List<String> args, port) {
  startTime = new DateTime.now();
  markov = new MarkovChain();
  bot = new BotConnector(port);

  storage = bot.createStorage("DCBot", "storage");

  storage.load();

  initTextCommands();

  APIDocs.init();

  print("[DCBot] Loading Plugin");

  eventManager = bot.createEventManager();

  {
    var sub = eventManager.on("message").listen((event) {
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
      handleLogging(event);
    });

    eventManager.registerSubscription(sub);
  }

  var sub = eventManager.on("command").listen((event) {
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

  eventManager.registerSubscription(sub);

  eventManager.onShutdown(() {
    print("[DCBot] Unloading Plugin");
    server.close(force: true);
    httpClient.close();
    textCommandStorage.destroy();
    storage.destroy();
    markovTimer.cancel();
    if (markovEnabled) {
      markov.save();
    }

    for (var timer in countdowns) {
    	timer.cancel();
    }

    /* Release Memory */
    markov = null;
  });

  bot.getConfig().then((config) {
    if (config['markov_load'] != null && !config['markov_load']) {
      return;
    } else {
      markov.load();
    }
  });
  
  setupServer().then((_) {
    print("[DCBot] Server Started");
    Neo.setup();
    GitLab.initialize();
  });

  markovTimer = new Timer.periodic(new Duration(seconds: 600), (timer) {
    if (markovEnabled) {
      markov.save();
    }
  });
}
