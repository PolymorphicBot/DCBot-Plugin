part of dcbot.plugin;

const String BASE_DARTDOC = "http://www.dartdocs.org/documentation/";

class CommandEvent {
  final String network;
  final String command;
  final String message;
  final String user;
  final String channel;
  final List<String> args;

  void reply(String message, {bool prefix: true, String prefixContent: "DirectCode"}) {
    bot.message(network, channel, (prefix ? "[${Color.BLUE}${prefixContent}${Color.RESET}] " : "") + message);
  }

  void require(String permission, void handle()) {
    bot.permission((it) => handle(), network, channel, user, permission);
  }

  void replyNotice(String message, {bool prefix: true, String prefixContent: "DirectCode"}) {
    bot.notice(network, user, (prefix ? "[${Color.BLUE}${prefixContent}${Color.RESET}] " : "") + message);
  }

  CommandEvent(this.network, this.command, this.message, this.user, this.channel, this.args);
}

void handleCommand(CommandEvent event) {
  if (event.channel.toLowerCase() == "#directcode") {
    switch (event.command) {
      case "github":
        event.reply("GitHub Organization: https://github.com/DirectMyFile");
        break;
      case "board":
        event.reply("All Ops are Board Members");
        break;
      case "members":
        event.reply("All Voices are Members");
        break;
      case "join-directcode":
        event.reply("To become a member, contact a board member.");
        break;
    }
  }

  switch (event.command) {
    case "broken":
      event.reply("kaendfinger breaks all the things.", prefix: false);
      break;
    case "hammertime":
      event.reply("U can't touch this.", prefix: false);
      break;
    case "hammer":
      event.reply(repeat("\u25AC", 4) + "\u258B", prefix: false);
      break;
    case "banhammer":
      event.reply("Somebody is bringing out the ban hammer! ${repeat("\u25AC", 4)}\u258B Ò╭╮Ó", prefix: false);
      break;
    case "today":
    case "date":
      event.reply(friendlyDate(new DateTime.now()), prefixContent: "Date");
      break;
    case "time":
      event.reply(friendlyTime(new DateTime.now()), prefixContent: "Time");
      break;
    case "now":
      event.reply("Now is " + friendlyDateTime(new DateTime.now()), prefixContent: "DCBot");
      break;
    case "yesterday":
      event.reply("Yesterday was " + friendlyDate(new DateTime.now().subtract(new Duration(days: 1))), prefixContent: "DCBot");
      break;
    case "tomorrow":
      event.reply("Tomorrow will be " + friendlyDate(new DateTime.now().add(new Duration(days: 1))), prefixContent: "DCBot");
      break;
    case "dfn":
      if (event.args.length != 1) {
        event.reply("> Usage: dfn <days>", prefix: false);
        return;
      }
      int days;
      try {
        days = int.parse(event.args[0]);
      } catch (e) {
        event.reply("> ${event.args[0]} is not a valid number.");
        return;
      }
      event.reply("${days} day${days != 1 ? "s" : ""} from now will be ${friendlyDate(new DateTime.now().add(new Duration(days: days)))}", prefixContent: "DCBot");
      break;
    case "dag":
      if (event.args.length != 1) {
        event.reply("> Usage: dag <days>", prefix: false);
        return;
      }
      int days;
      try {
        days = int.parse(event.args[0]);
      } catch (e) {
        event.reply("> ${event.args[0]} is not a valid number.");
        return;
      }
      event.reply("${days} day${days != 1 ? "s" : ""} ago was ${friendlyDate(new DateTime.now().subtract(new Duration(days: days)))}", prefixContent: "DCBot");
      break;
    case "help":
      event.replyNotice("DCBot is the official DirectCode IRC Bot.", prefixContent: "Help");
      event.replyNotice("For a list of commands, use \$commands", prefixContent: "Help");
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
            event.replyNotice("${plugin}: ${cmds.isEmpty ? "No Commands" : cmds.keys.join(', ')}", prefixContent: "Commands");
          });
        }
      });
      break;
    case "plugins":
      bot.get("plugins").then((response) {
        event.reply("${response['plugins'].join(', ')}", prefixContent: "Plugins");
      });
      break;
    case "stats":
      var msgsTotal = storage.get("messages_total", 0);
      var networkMsgsTotal = storage.get("${event.network}_messages_total", 0);
      var channelMsgsTotal = storage.get("${event.network}_${event.channel}_messages_total", 0);
      event.replyNotice("Bot - Total Messages: ${msgsTotal}", prefixContent: "Statistics");
      event.replyNotice("Network - Total Messages: ${networkMsgsTotal}", prefixContent: "Statistics");
      event.replyNotice("Channel - Total Messages: ${channelMsgsTotal}", prefixContent: "Statistics");
      var users = [];
      storage.map.keys.where((it) => it.startsWith("${event.network}_${event.channel}_user_")).forEach((name) {
        users.add({
          "name": name.replaceAll("${event.network}_${event.channel}_user_", "").replaceAll("_messages_total", ""),
          "count": storage.get(name)
        });
      });

      users.sort((a, b) => b['count'].compareTo(a['count']));

      if (users.isNotEmpty) {
        var most = users.first['name'];

        event.replyNotice("Most Talkative User on ${event.channel}: ${most}", prefixContent: "Statistics");
      }
      break;
    case "month":
      var m = new DateTime.now().month;
      event.reply("The Month is ${monthName(m)} (the ${m}${friendlyDaySuffix(m)} month)", prefixContent: "DCBot");
      break;
    case "reload":
      event.require("plugins.reload", () {
        event.reply("Reloading Plugins", prefixContent: "DCBot");
        bot.send("reload-plugins", {
          "network": event.network
        });
      });
      break;
    case "day":
      event.reply("The Day is ${dayName(new DateTime.now().weekday)}", prefixContent: "DCBot");
      break;
    case "dart-version":
      var chan = event.args.length == 1 ? event.args[0] : "stable";
      new HttpClient().getUrl(Uri.parse("https://commondatastorage.googleapis.com/dart-archive/channels/${chan}/${chan == "stable" ? "release" : "raw"}/latest/VERSION")).then((req) => req.close()).then((response) {
        response.transform(UTF8.decoder).join().then((value) {
          if (response.statusCode != 200) {
            event.reply("Invalid Channel", prefixContent: "Dart");
            return;
          }
          var json = JSON.decode(value);
          var rev = json['revision'];
          var v = json['version'];
          event.reply("${v} (${rev})", prefixContent: "Dart");
        });
      });
      break;
    case "year":
      event.reply("The Year is ${new DateTime.now().year}", prefixContent: "DCBot");
      break;
    case "cycle":
      event.require("command.cycle", () {
        bot.send("part", {
          "network": event.network,
          "channel": event.channel
        });

        bot.send("join", {
          "network": event.network,
          "channel": event.channel
        });
      });
      break;
    case "dartdoc":
      if (event.args.length > 2 || event.args.length < 1) {
        event.reply("> Usage: dartdoc <package> [version]", prefix: false);
      } else {
        String package = event.args[0];
        String version = event.args.length == 2 ? event.args[1] : "latest";
        dartdocUrl(event.args[0], version).then((url) {
          if (url == null) {
            event.reply("> package not found '${package}@${version}'", prefix: false);
          } else {
            event.reply("> Documentation: ${url}", prefix: false);
          }
        });
      }
      break;
    case "pub-latest":
      if (event.args.length == 0) {
        event.reply("> Usage: pub-latest <package>", prefix: false);
      } else {
        latestPubVersion(event.args[0]).then((version) {
          if (version == null) {
            event.reply("> No Such Package: ${event.args[0]}", prefix: false);
          } else {
            event.reply("> Latest Version: ${version}", prefix: false);
          }
        });
      }
      break;
    case "pub-description":
      if (event.args.length == 0) {
        event.reply("> Usage: pub-description <package>", prefix: false);
      } else {
        pubDescription(event.args[0]).then((desc) {
          if (desc == null) {
            event.reply("> No Such Package: ${event.args[0]}", prefix: false);
          } else {
            event.reply("> Description: ${desc}", prefix: false);
          }
        });
      }
      break;
    case "pub-downloads":
      if (event.args.length == 0) {
        event.reply("> Usage: pub-downloads <package>", prefix: false);
      } else {
        String package = event.args[0];
        pubPackage(package).then((info) {
          if (info == null) {
            event.reply("> No Such Package: ${event.args[0]}", prefix: false);
          } else {
            event.reply("> Download Count: ${info["downloads"]}", prefix: false);
          }
        });
      }
      break;
    case "pub-uploaders":
      if (event.args.length == 0) {
        event.reply("> Usage: pub-uploaders <package>", prefix: false);
      } else {
        String package = event.args[0];
        pubUploaders(package).then((authors) {
          if (authors == null) {
            event.reply("> No Such Package: ${event.args[0]}", prefix: false);
          } else {
            event.reply("> Uploaders: ${authors.join(", ")}", prefix: false);
          }
        });
      }
      break;
  }
}

Future<String> dartdocUrl(String package, [String version = "latest"]) {
  if (version == "latest") {
    return latestPubVersion(package).then((version) {
      if (version == null) {
        return new Future.value(null);
      }
      return new Future.value("${BASE_DARTDOC}${package}/${version}");
    });
  } else {
    return new Future.value("${BASE_DARTDOC}${package}/${version}");
  }
}

Future<Map<String, Object>> pubPackage(String package) {
  return httpClient.get("https://pub.dartlang.org/api/packages/${package}").then((http.Response response) {
    if (response.statusCode == 404) {
      return new Future.value(null);
    } else {
      return new Future.value(JSON.decoder.convert(response.body));
    }
  });
}

Future<String> pubDescription(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      return new Future.value(val["latest"]["pubspec"]["description"]);
    }
  });
}

Future<List<String>> pubUploaders(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      return new Future.value(val["uploaders"]);
    }
  });
}

Future<List<String>> pubVersions(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      var versions = [];
      val["versions"].forEach((version) {
        versions.add(version["name"]);
      });
      return new Future.value(versions);
    }
  });
}

Future<String> latestPubVersion(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      return new Future.value(val["latest"]["pubspec"]["version"]);
    }
  });
}
