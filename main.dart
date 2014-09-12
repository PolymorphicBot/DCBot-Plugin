library dcbot.plugin;

import "dart:io";
import "dart:convert";

import "package:irc/irc.dart" show Color;
import "package:polymorphic_bot/api.dart";

import "package:github/dates.dart";

APIConnector bot;

void main(List<String> args, port) {
  bot = new APIConnector(port);

  print("[DirectCode] Loading Plugin");

  bot.handleEvent((event) {
    switch (event['event']) {
      case "command":
        handleCommand(event);
        break;
    }
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
      reply("▬▬▬▬▬▬▬▋", prefix: false);
      break; 
    case "banhammer":
      reply("Somebody is bringing out the ban hammer! ▬▬▬▬▬▬▬▋ Ò╭╮Ó", prefix: false);
      break;
    case "today":
    case "date":
      reply(friendlyDate(new DateTime.now()), prefixContent: "Date");
      break;
    case "time":
      reply(friendlyTime(new DateTime.now()), prefixContent: "Time");
      break;
    case "now":
      reply("Right now is: " + friendlyDateTime(new DateTime.now()), prefixContent: "DCBot");
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
    case "month":
      var m = new DateTime.now().month;
      reply("The Month is ${monthName(m)} (the ${m}${friendlyDaySuffix(m)} month)");
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
  }
}
