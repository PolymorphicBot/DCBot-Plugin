library dcbot.plugin;

import "dart:async";
import "dart:io";
import "dart:convert";

import "package:irc/irc.dart" show Color;
import "package:polymorphic_bot/api.dart";

import "package:quiver/strings.dart";
import "package:quiver/pattern.dart";

import "package:github/dates.dart";

import "package:route/server.dart";
import "package:http_server/http_server.dart";

part "storage.dart";
part "slack.dart";
part "server.dart";
part "buffer.dart";
part "regex.dart";

APIConnector bot;

Storage storage;

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
        handleCommand(event);
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

void handleCommand(data) {
  var network = data['network'] as String;
  var user = data['from'] as String;
  var target = data['target'] as String;
  var command = data['command'] as String;
  var args = data['args'] as List<String>;

  void reply(String message, {bool prefix: true, String prefixContent: "DirectCode"}) {
    bot.message(network, target, (prefix ? "[${Color.BLUE}${prefixContent}${Color.RESET}] " : "") + message);
  }
  
  void replyNotice(String message, {bool prefix: true, String prefixContent: "DirectCode"}) {
    bot.notice(network, user, (prefix ? "[${Color.BLUE}${prefixContent}${Color.RESET}] " : "") + message);
  }

  void require(String permission, void handle()) {
    bot.permission((it) => handle(), network, target, user, permission);
  }
  
  if (target.toLowerCase() == "#directcode") {
    switch (command) {
      case "github":
        reply("GitHub Organization: https://github.com/DirectMyFile");
        break;
      case "board":
        reply("All Ops are Board Members");
        break;
      case "members":
        reply("All Voices are Members");
        break;
      case "join-directcode":
        reply("To become a member, contact a board member.");
        break;
    }
  }

  switch (command) {
    case "broken":
      reply("kaendfinger breaks all the things.", prefix: false);
      break;
    case "hammertime":
      reply("U can't touch this.", prefix: false);
      break;
    case "hammer":
      reply(repeat("\u25AC", 4) + "\u258B", prefix: false);
      break; 
    case "banhammer":
      reply("Somebody is bringing out the ban hammer! ${repeat("\u25AC", 4)}\u258B Ò╭╮Ó", prefix: false);
      break;
    case "today":
    case "date":
      reply(friendlyDate(new DateTime.now()), prefixContent: "Date");
      break;
    case "time":
      reply(friendlyTime(new DateTime.now()), prefixContent: "Time");
      break;
    case "now":
      reply("Now is " + friendlyDateTime(new DateTime.now()), prefixContent: "DCBot");
      break;
    case "yesterday":
      reply("Yesterday was " + friendlyDate(new DateTime.now().subtract(new Duration(days: 1))), prefixContent: "DCBot");
      break;
    case "tomorrow":
      reply("Tomorrow will be " + friendlyDate(new DateTime.now().add(new Duration(days: 1))), prefixContent: "DCBot");
      break;
    case "dfn":
      if (args.length != 1) {
        reply("> Usage: dfn <days>", prefix: false);
        return;
      }
      int days;
      try {
        days = int.parse(args[0]);
      } catch (e) {
        reply("> ${args[0]} is not a valid number.");
        return;
      }
      reply("${days} day${days != 1 ? "s" : ""} from now will be ${friendlyDate(new DateTime.now().add(new Duration(days: days)))}", prefixContent: "DCBot");
      break;
    case "dag":
      if (args.length != 1) {
        reply("> Usage: dag <days>", prefix: false);
        return;
      }
      int days;
      try {
        days = int.parse(args[0]);
      } catch (e) {
        reply("> ${args[0]} is not a valid number.");
        return;
      }
      reply("${days} day${days != 1 ? "s" : ""} ago was ${friendlyDate(new DateTime.now().subtract(new Duration(days: days)))}", prefixContent: "DCBot");
      break;
    case "help":
      replyNotice("DCBot is the official DirectCode IRC Bot.", prefixContent: "Help");
      replyNotice("For a list of commands, use \$commands", prefixContent: "Help");
      break;
    case "commands":
      bot.get("plugins").then((responseA) {
        List<String> pluginNames = responseA['plugins'];
        for (var plugin in pluginNames) {
          bot.get("plugin-commands", {
            "plugin": plugin
          }).then((Map<String, Map<String, dynamic>> cmds) {
            if (cmds == null) {
              return;
            }
            replyNotice("${plugin}: ${cmds.isEmpty ? "No Commands" : cmds.keys.join(', ')}", prefixContent: "Commands");
          });
        }
      });
      break;
    case "plugins":
      bot.get("plugins").then((response) {
        reply("${response['plugins'].join(', ')}", prefixContent: "Plugins");
      });
      break;
    case "stats":
      var msgsTotal = storage.get("messages_total", 0);
      var networkMsgsTotal = storage.get("${network}_messages_total", 0);
      var channelMsgsTotal = storage.get("${network}_${target}_messages_total", 0);
      replyNotice("Bot - Total Messages: ${msgsTotal}", prefixContent: "Statistics");
      replyNotice("Network - Total Messages: ${networkMsgsTotal}", prefixContent: "Statistics");
      replyNotice("Channel - Total Messages: ${channelMsgsTotal}", prefixContent: "Statistics");
      var users = [];
      storage.map.keys.where((it) => it.startsWith("${network}_${target}_user_")).forEach((name) {
        users.add({
          "name": name.replaceAll("${network}_${target}_user_", "").replaceAll("_messages_total", ""),
          "count": storage.get(name)
        });
      });
      
      users.sort((a, b) => b['count'].compareTo(a['count']));
      
      if (users.isNotEmpty) {
        var most = users.first['name'];
        
        replyNotice("Most Talkative User on ${target}: ${most}", prefixContent: "Statistics");
      }
      break;
    case "month":
      var m = new DateTime.now().month;
      reply("The Month is ${monthName(m)} (the ${m}${friendlyDaySuffix(m)} month)", prefixContent: "DCBot");
      break;
    case "reload":
      require("plugins.reload", () {
        reply("Reloading Plugins", prefixContent: "DCBot");
        bot.send("reload-plugins", {
          "network": network
        });
      });
      break;
    case "day":
      reply("The Day is ${dayName(new DateTime.now().weekday)}", prefixContent: "DCBot");
      break;
    case "dart-version":
      var chan = args.length == 1 ? args[0] : "stable";
      new HttpClient().getUrl(Uri.parse("https://commondatastorage.googleapis.com/dart-archive/channels/${chan}/${chan == "stable" ? "release" : "raw"}/latest/VERSION"))
        .then((req) => req.close())
        .then((response) {
        response.transform(UTF8.decoder).join().then((value) {
          if (response.statusCode != 200) {
            reply("Invalid Channel", prefixContent: "Dart");
            return;
          }
          var json = JSON.decode(value);
          var rev = json['revision'];
          var v = json['version'];
          reply("${v} (${rev})", prefixContent: "Dart");
        });
      });
      break;
    case "year":
      reply("The Year is ${new DateTime.now().year}", prefixContent: "DCBot");
      break;
    case "cycle":
      require("command.cycle", () {
        bot.send("part", {
          "network": network,
          "channel": target
        });
        
        bot.send("join", {
          "network": network,
          "channel": target
        });
      });
  }
}
