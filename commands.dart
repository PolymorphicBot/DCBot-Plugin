part of dcbot.plugin;

var countdowns = [];

const String BASE_DARTDOC = "http://www.dartdocs.org/documentation/";

class CustomCommandEvent {
  final String network;
  final String command;
  final String message;
  final String user;
  final String channel;
  final List<String> args;

  void reply(String message, {bool prefix: true, String prefixContent: "DCBot"}) {
    bot.sendMessage(network, channel, (prefix ? "[${Color.BLUE}${prefixContent}${Color.RESET}] " : "") + message);
  }

  void require(String permission, void handle()) {
    bot.checkPermission((it) => handle(), network, channel, user, permission);
  }

  void replyNotice(String message, {bool prefix: true, String prefixContent: "DCBot"}) {
    bot.sendNotice(network, user, (prefix ? "[${Color.BLUE}${prefixContent}${Color.RESET}] " : "") + message);
  }


  CustomCommandEvent(this.network, this.command, this.message, this.user, this.channel, this.args);
}

void handleCommand(CustomCommandEvent event) {
  if (event.channel.toLowerCase() == "#directcode") {
    switch (event.command) {
      case "github":
        event.reply("GitHub Organization: https://github.com/DirectMyFile", prefixContent: "DirectCode");
        break;
      case "board":
        event.reply("All Ops are Board Members", prefixContent: "DirectCode");
        break;
      case "members":
        event.reply("All Voices are Members", prefixContent: "DirectCode");
        break;
      case "join-directcode":
        event.reply("To become a member, contact a board member.", prefixContent: "DirectCode");
        break;
    }
  }

  void linuxRelease(String name) {
    httpClient.get("https://www.kernel.org/releases.json").then((response) {
      var json = JSON.decode(response.body);
      var releases = json["releases"];
      releases.forEach((r) {
        if (r["moniker"] == name.toLowerCase()) {
          var rtn = "$name ${r['version']} released on ${r["released"]["isodate"]}";
          if (r["iseol"] == true) rtn += " EOL";
          event.reply(Color.DARK_GREEN + rtn, prefixContent: "Linux");
        }
      });
    });
}

  switch (event.command) {
    case "broken":
      if (event.args.length == 0) {
        event.reply("kaendfinger breaks all the things.", prefix: false);
      } else {
        event.reply("${event.args.join(' ')} breaks all the things.", prefix: false);
      }
      break;
    case "uptime":
      var diff = new DateTime.now().difference(startTime);
      var days = diff.inDays;
      var hours = diff.inHours - (days * 24);
      var minutes = diff.inMinutes - (hours * 60);
      var seconds = diff.inSeconds - (minutes * 60);
      var str = "${days} days, ${hours} hours, ${minutes} minutes, ${seconds} seconds";
      event.reply("${str}", prefixContent: "Uptime");
      break;
    case "countdown":
      if (event.args.length != 1) {
        event.reply("Usage: countdown <seconds>", prefixContent: "Countdown");
        return;
      }

      int seconds;

      try {
        seconds = int.parse(event.args[0]);
      } catch (e) {
        event.reply("Invalid Number", prefixContent: "Countdown");
        return;
      }

      int i = seconds;
      Timer timer = new Timer.periodic(new Duration(seconds: 1), (timer) {
        if (i > 5 && !((i % 5) == 0)) {
          i--;
          return;
        }

        if (i == 0) {
          event.reply("Complete.", prefixContent: "Countdown");
          timer.cancel();
          countdowns.remove(timer);
        } else {
          event.reply("${i}", prefixContent: "Countdown");
        }

        i--;
      });

      countdowns.add(timer);
      break;
    case "hammertime":
      if (event.args.length == 0) {
        event.reply("U can't touch this.", prefix: false);
      } else {
        event.reply("U can't touch ${event.args.join(' ')}.", prefix: false);
      }
      break;
    case "list-methods":
      if (event.args.isEmpty) {
        bot.getPlugins().then((plugins) {
          for (var pn in plugins) {
            plugin.getRemoteMethods(pn).then((methods) {
              var names = methods.map((it) => it.name).toList();
              if (names.isEmpty) {
                return;
              }
              event.replyNotice("> ${pn}: ${names.join(", ")}", prefix: false);
            });
          }
        });
      } else {
        event.reply("> Usage: list-methods", prefix: false);
      }
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
      event.reply("Now is " + friendlyDateTime(new DateTime.now()));
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

        if (days >= 100000000) {
          throw "FAIL";
        }
      } catch (e) {
        event.reply("> ${event.args[0]} is not a valid number.", prefix: false);
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

        if (days >= 100000000) {
          throw "FAIL";
        }
      } catch (e) {
        event.reply("> ${event.args[0]} is not a valid number.", prefix: false);
        return;
      }
      event.reply("${days} day${days != 1 ? "s" : ""} ago was ${friendlyDate(new DateTime.now().subtract(new Duration(days: days)))}", prefixContent: "DCBot");
      break;
    
    case "help":
      event.replyNotice("DCBot is the official DirectCode IRC Bot.", prefixContent: "Help");
      event.replyNotice("For a list of commands, use \$commands", prefixContent: "Help");
      break;
    
    case "commands":
      plugin.getPlugins().then((plugins) {
        for (var pluginName in plugins) {
          bot.getCommands(pluginName).then((commands) {
            if (commands == null) {
              return;
            }
            event.replyNotice("${pluginName}: ${commands.isEmpty ? "No Commands" : commands.map((it) => it.name).join(', ')}", prefixContent: "Commands");
          });
        }
      });
      break;
      
    case "is-bot":
      if (event.args.length != 1) {
        event.reply("> Usage: is-bot <user>", prefix: false);
      } else {
        bot.isUserABot(event.network, event.args[0]).then((isBot) {
          if (isBot) {
            event.reply("> ${event.args[0]} is a bot.", prefix: false);
          } else {
            event.reply("> ${event.args[0]} is not a bot", prefix: false);
          }
        });
      }
      break;
    
    case "command":
      if (event.args.length != 1) {
        event.reply("Usage: command <command name>", prefixContent: "Command Information");
      }
      
      bot.doesCommandExist(event.args[0]).then((exists) {
        if (exists) {
          return bot.getCommand(event.args[0]);
        } else {
          event.reply("Unknown Command: ${event.args[0]}", prefixContent: "Command Information");
          return null;
        }
      }).then((CommandInfo info) {
        if (info == null) {
          return;
        }
        
        var usage = info.usage;
        var description = info.description;

        if (description != null) {
          event.reply("Description: ${description}", prefixContent: "Command Information");
        }

        if (usage != null) {
          event.reply("Usage: ${event.args[0]} ${usage}", prefixContent: "Command Information");
        }
      });
      break;
    case "plugins":
      plugin.getPlugins().then((plugins) {
        event.reply("${plugins.join(', ')}", prefixContent: "Plugins");
      });
      break;
    
    case "stats":
      var msgsTotal = storage.getInteger("messages_total", defaultValue: 0);
      var cmdsTotal = storage.getInteger("commands_total", defaultValue: 0);
      var networkMsgsTotal = storage.getInteger("${event.network}_messages_total", defaultValue: 0);
      var networkCmdsTotal = storage.getInteger("${event.network}_commands_total", defaultValue: 0);
      var channelMsgsTotal = storage.getInteger("${event.network}_${event.channel}_messages_total", defaultValue: 0);
      var channelCmdsTotal = storage.getInteger("${event.network}_${event.channel}_commands_total", defaultValue: 0);

      event.replyNotice("Bot - Total Messages: ${msgsTotal}", prefixContent: "Statistics");
      event.replyNotice("Users - Total Command Runs: ${cmdsTotal}", prefixContent: "Statistics");
      event.replyNotice("Network - Total Messages: ${networkMsgsTotal}", prefixContent: "Statistics");
      event.replyNotice("Channel - Total Messages: ${channelMsgsTotal}", prefixContent: "Statistics");
      event.replyNotice("Network - Total Command Runs: ${networkCmdsTotal}", prefixContent: "Statistics");
      event.replyNotice("Channel - Total Command Runs: ${channelCmdsTotal}", prefixContent: "Statistics");

      {
        var users = <Map<String, dynamic>>[];
        storage.keys.where((it) => it.startsWith("${event.network}_${event.channel}_user_")).forEach((name) {
          users.add({
            "name": name.replaceAll("${event.network}_${event.channel}_user_", "").replaceAll("_messages_total", ""),
            "count": storage.getInteger(name, defaultValue: 0)
          });
        });
        
        void combine(String a, String b) {
          var ai = users.firstWhere((it) => it['name'] == a, orElse: () => null);
          var bi = users.firstWhere((it) => it['name'] == b, orElse: () => null);
          
          if (ai != null && bi != null) {
            users.remove(bi);
            ai['count'] += bi['count'];
          }
        }
        
        combine("kaendfinger", "kaendfork");
        combine("samrg472", "deathcrazyuberlironman");
        combine("samrg472", "samfork");

        users.sort((a, b) => b['count'].compareTo(a['count']));

        if (users.isNotEmpty) {
          var most = users.first['name'];
          var actives = (users.take(6).toList()..removeAt(0)).map((it) => it['name']);
          var least = users.last['name'];

          event.replyNotice("Most Active User on ${event.channel}: ${most}", prefixContent: "Statistics");
          event.replyNotice("Active Users on ${event.channel}: ${actives.join(", ")}", prefixContent: "Statistics");
        }
      }
      break;
    case "month":
      var m = new DateTime.now().month;
      event.reply("The Month is ${monthName(m)} (the ${m}${friendlyDaySuffix(m)} month)", prefixContent: "DCBot");
      break;
    case "day":
      event.reply("The Day is ${dayName(new DateTime.now().weekday)}", prefixContent: "DCBot");
      break;
    case "dart-version":
      if (event.args.length >= 2) {
        event.reply("Usage: dart-version [channel]");
        return;
      }
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
    case "addtxtcmd":
      event.require("txtcmds.add", () {
        if (event.args.length < 2) {
          event.reply("Usage: addtxtcmd <command> <text>", prefixContent: "Text Commands");
        } else {
          var cmd = event.args[0];
          var text = event.args.sublist(1).join(" ");
          textCommandStorage.setString(cmd, text);
          event.reply("Command Added", prefixContent: "Text Commands");
        }
      });
      break;
    case "removetxtcmd":
      event.require("txtcmds.remove", () {
        if (event.args.length != 1) {
          event.reply("Usage: removetxtcmd <command>", prefixContent: "Text Commands");
        } else {
          var cmd = event.args[0];
          textCommandStorage.remove(cmd);
          event.reply("Command Removed", prefixContent: "Text Commands");
        }
      });
      break;
    case "addchannelcmd":
      event.require("txtcmds.channel.add", () {
        if (event.args.length < 2) {
          event.reply("Usage: addchannelcmd <command> <text>", prefixContent: "Channel Commands");
        } else {
          var cmd = event.args[0];
          var text = event.args.sublist(1).join(" ");
          textCommandStorage.setString(event.network + " " + event.channel + " " + cmd, text);
          event.reply("Command Added", prefixContent: "Channel Commands");
        }
      });
      break;
    case "listtxtcmds":
      event.require("txtcmds.list", () {
        var globals = textCommandStorage.keys.where((it) {
          return !it.contains(" ");
        }).toList();
        
        paginate(globals, 8, (page, items) {
          event.reply("${items.join(", ")}", prefixContent: "Text Commands");
        });
      });
      break;
    case "listchannelcmds":
      event.require("txtcmds.channel.list", () {
        var ours = textCommandStorage.keys.where((it) {
          return it.startsWith("${event.network} ${event.channel} ");
        }).map((it) => it.split(" ").last).toList();
        
        paginate(ours, 8, (page, items) {
          event.reply("${items.join(", ")}", prefixContent: "Channel Commands");
        });
      });
      break;
    case "removechannelcmd":
      event.require("txtcmds.channel.remove", () {
        if (event.args.length != 1) {
          event.reply("Usage: removechannelcmd <command>", prefixContent: "Channel Commands");
        } else {
          var cmd = event.args[0];
          textCommandStorage.remove(event.network + " " + event.channel + " " + cmd);
          event.reply("Command Removed", prefixContent: "Channel Commands");
        }
      });
      break;
    case "addgchannelcmd":
      event.require("txtcmds.channel.global.add", () {
        if (event.args.length < 2) {
          event.reply("Usage: addgchannelcmd <command> <text>", prefixContent: "Global Channel Commands");
        } else {
          var cmd = event.args[0];
          var text = event.args.sublist(1).join(" ");
          textCommandStorage.setString(event.channel + " " + cmd, text);
          event.reply("Command Added", prefixContent: "Global Channel Commands");
        }
      });
      break;
    case "listgchannelcmds":
      event.require("txtcmds.channel.list", () {
        var ours = textCommandStorage.keys.where((it) {
          return it.startsWith("${event.channel} ");
        }).map((it) => it.split(" ").last).toList();
        
        paginate(ours, 8, (page, items) {
          event.reply("${items.join(", ")}", prefixContent: "Global Channel Commands");
        });
      });
      break;
    case "removegchannelcmd":
      event.require("txtcmds.channel.global.remove", () {
        if (event.args.length != 1) {
          event.reply("Usage: removegchannelcmd <command>", prefixContent: "Global Channel Commands");
        } else {
          var cmd = event.args[0];
          textCommandStorage.remove(event.channel + " " + cmd);
          event.reply("Command Removed", prefixContent: "Global Channel Commands");
        }
      });
      break;
    case "about-bot":
      event.replyNotice("I am written in 100% Dart. I use isolates to separate functionality into plugins. This allows me to reload plugins without restarting the full bot.");
      event.replyNotice("You can find all of my functionality here as plugins: https://github.com/PolymorphicBot/");
      break;
    case "neo":
      Neo.handleCommand(event);
      break;
    case "linux-stable":
      linuxRelease("Stable");
      break;
    case "linux-mainline":
      linuxRelease("Mainline");
      break;
    case "linux-next":
      linuxRelease("Linux-Next");
      break;
    case "linux-longterm":
      linuxRelease("Longterm");
      break;
  }

  handleServicesCommand(event);
}

void paginate(List<dynamic> allItems, int per, void handler(int page, List<dynamic> items)) {
  var x = 0;
  var buff = [];
  var p = 1;
  for (var i = 0; i < allItems.length; i++) {
    x++;
    buff.add(allItems[i]);
    if (x == per || i + 1 == allItems.length) {
      handler(p, new List<dynamic>.from(buff));
      x = 0;
      buff.clear();
      p++;
    }
  }
}