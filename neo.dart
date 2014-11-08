part of dcbot.plugin;

void setupNeo() {
  router.serve("/teamcity/neo", method: "POST").listen((request) {
    var response = request.response;
    return HttpBodyHandler.processRequest(request).then((body) {
      handleNeoTeamCityHook(body.body);
      response.write("");
      return response.close();
    });
  });
}

void handleNeoTeamCityHook(Map<String, dynamic> json) {
  Map<String, dynamic> build = json['build'];
  String fullName = build['buildFullName'];

  if (!fullName.startsWith("neo :: ")) {
    return;
  }

  switch (build['notifyType']) {
    case "buildStarted":
      onNeoBuildStarted(build);
      break;
  }
}

void onNeoBuildStarted(Map<String, dynamic> build) {
  String displayName = build['fullName'].replaceAll("neo :: ", "");
  String device = displayName.replaceAll(" ", "_").toLowerCase();
  List<String> subscribers = storage.get("neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}", []);

  for (var subscriber in subscribers) {
    var split = subscriber.split(":");
    var network = split[0];
    var user = split[1];
    bot.message(network, user, "${Color.BLUE}[${Color.RESET}neo${Color.BLUE}]${Color.RESET} Build Started for the ${displayName}.");
  }
}

void handleNeoCommand(CustomCommandEvent event) {
  var _args = new List<String>.from(event.args);

  if (_args.isEmpty) {
    event.reply("Usage: neo <command> [args]", prefixContent: "neo");
    return;
  }
  var cmd = _args.removeAt(0);
  var args = _args;

  switch (cmd) {
    case "subscribe":
      var device = args.join(" ");
      var key = "neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}";
      List<String> subscribers = storage.get(key, []);
      if (subscribers.contains("${event.network}:${event.user}")) {
        event.reply("You are already subscribed to build notifications for the ${device}.");
        return;
      }

      subscribers.add("${event.network}:${event.user}");

      storage.set(key, subscribers);

      event.reply("You have been subscribed to build notifications for the ${device}.");
      break;
    default:
      event.reply("No Such Command '${cmd}'", prefixContent: "neo");
      break;
  }
}