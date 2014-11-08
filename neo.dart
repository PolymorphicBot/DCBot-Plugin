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
    case "buildFixed":
    case "buildSuccessful":
      onNeoBuildSuccess(build);
      break;
  }
}

Future<Map<String, dynamic>> fetchNeoDescriptor() {
  return http.get("http://git.directcode.org/neo/neo/raw/master/default.json").then((response) {
    return JSON.decode(response.body);
  });
}

class NeoDevice {
  String name;
  String codename;
  String manufacturer;
}

Future<List<NeoDevice>> deviceInformation() {
  return fetchNeoDescriptor().then((deviceInformation) {
    var devices = [];
    for (var dev in deviceInformation) {
      var device = new NeoDevice();
      device.name = dev['name'];
      device.codename = dev['codename'];
      device.manufacturer = dev['manufacturer'];
    }
  });
}

Future<List<String>> deviceNames() {
  return fetchNeoDescriptor().then((descriptor) {
    return descriptor['devices'].map((device) => device['name']).toList();
  });
}

void onNeoBuildStarted(Map<String, dynamic> build) {
  String displayName = build['buildFullName'].replaceAll("neo :: ", "");
  String device = displayName.replaceAll(" ", "_").toLowerCase();
  List<String> subscribers = storage.get("neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}", []);

  for (var subscriber in subscribers) {
    var split = subscriber.split(":");
    var network = split[0];
    var user = split[1];
    bot.message(network, user, "${Color.BLUE}[${Color.RESET}neo${Color.BLUE}]${Color.RESET} Build Started for the ${displayName}.");
  }
}

void onNeoBuildSuccess(Map<String, dynamic> build) {
  String displayName = build['buildFullName'].replaceAll("neo :: ", "");
  String device = displayName.replaceAll(" ", "_").toLowerCase();
  List<String> subscribers = storage.get("neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}", []);

  for (var subscriber in subscribers) {
    var split = subscriber.split(":");
    var network = split[0];
    var user = split[1];
    bot.message(network, user, "${Color.BLUE}[${Color.RESET}neo${Color.BLUE}]${Color.RESET} Build Finished Successfully for the ${displayName}.");
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
      if (args.isEmpty) {
        event.reply("Usage: neo subscribe <device>", prefixContent: "neo");
        return;
      }
      var device = args.join(" ");

      deviceNames().then((names) {
        if (!names.contains(device)) {
          event.reply("Invalid Device. To get a list of devices, please use '\$neo devices'.", prefixContent: "neo");
          return;
        }

        var key = "neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}";
        List<String> subscribers = storage.get(key, []);
        if (subscribers.contains("${event.network}:${event.user}")) {
          event.reply("You are already subscribed to build notifications for the ${device}.", prefixContent: "neo");
          return;
        }
        subscribers.add("${event.network}:${event.user}");
        storage.set(key, subscribers);
        event.reply("You have been subscribed to build notifications for the ${device}.", prefixContent: "neo");
      });
      break;
    case "unsubscribe":
      if (args.isEmpty) {
        event.reply("Usage: neo unsubscribe <device>", prefixContent: "neo");
        return;
      }
      var device = args.join(" ");

      deviceNames().then((names) {
        if (!names.contains(device)) {
          event.reply("Invalid Device. To get a list of devices, please use '\$neo devices'.", prefixContent: "neo");
          return;
        }

        var key = "neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}";
        List<String> subscribers = storage.get(key, []);
        if (!subscribers.contains("${event.network}:${event.user}")) {
          event.reply("You are not subscribed to build notifications for the ${device}.", prefixContent: "neo");
          return;
        }
        subscribers.remove("${event.network}:${event.user}");
        storage.set(key, subscribers);
        event.reply("You are no longer subscribed to build notifications for the ${device}.", prefixContent: "neo");
      });
      break;
    case "subscriptions":
      if (args.isNotEmpty) {
        event.reply("Usage: neo subscriptions", prefixContent: "neo");
        return;
      }
      var subs = storage.json.keys.where((key) {
        return key.startsWith("neo.device_subscribe.") && storage.get(key, []).contains(event.network + ":" + event.user);
      }).map((key) => key.replaceAll("neo.device_subscribe.", "").replaceAll("_", " "))
        .map((key) => key.split(" ").map((it) => it[0].toUpperCase() + it.substring(1)).join(" "))
        .toList();
      if (subs.isEmpty) {
        event.reply("You are not subscribed to any devices.", prefixContent: "neo");
      } else {
        event.reply("Subscriptions: ${subs.join(", ")}", prefixContent: "neo");
      }
      break;
    case "devices":
      if (args.isNotEmpty) {
        event.reply("Usage: neo devices", prefixContent: "neo");
        return;
      }
      deviceNames().then((devices) {
        event.reply("Devices: ${devices.join(", ")}", prefixContent: "neo");
      });
      break;
    case "device":
      if (args.isEmpty) {
        event.reply("Usage: neo device <name|codename>", prefixContent: "neo");
        return;
      }
      var device = args.join(" ");
      deviceInformation().then((devices) {

      });
      break;
    default:
      event.reply("No Such Command '${cmd}'", prefixContent: "neo");
      break;
  }
}