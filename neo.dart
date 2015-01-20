part of dcbot.plugin;

class NeoDevice {
  String name;
  String codename;
  String manufacturer;
}

class Neo {
  static void setup() {
    eventBus.on("neo.teamcity.hook").listen((data) {
      handleTeamCityHook(data);
    });
  }

  static void handleTeamCityHook(Map<String, dynamic> json) {
    Map<String, dynamic> build = json['build'];

    if (build == null || build['notifyType'] == null) return;
    
    switch (build['notifyType']) {
      case "buildStarted":
        onBuildStarted(build);
        break;
      case "buildFinished":
        onBuildFinished(build);
        break;
      default:
        break;
    }
  }

  static Future<Map<String, dynamic>> getIssue(int id) {
    return http.get("http://git.directcode.org/api/v3/projects/34/issues?private_token=DdZEzSYb-3up_weLguVC").then((r) {
      return JSON.decode(r.body);
    }).then((l) {
      return l.firstWhere((it) => it["iid"] == id, orElse: () {
        throw new Exception("ERROR");
      });
    });
  }

  static Future<List<Map<String, dynamic>>> getIssues() {
    return http.get("http://git.directcode.org/api/v3/projects/34/issues?private_token=DdZEzSYb-3up_weLguVC&per_page=50000").then((r) {
      return JSON.decode(r.body);
    });
  }

  static Future<Map<String, dynamic>> fetchDescriptor() {
    return http.get("http://git.directcode.org/neo/neo/raw/master/default.json").then((response) {
      return JSON.decode(response.body);
    });
  }

  static Future<List<NeoDevice>> deviceInformation() {
    return fetchDescriptor().then((descriptor) {
      var deviceInformation = descriptor['devices'];
      var devices = [];
      for (var dev in deviceInformation) {
        var device = new NeoDevice();
        device.name = dev['name'];
        device.codename = dev['codename'];
        device.manufacturer = dev['manufacturer'];
        devices.add(device);
      }
      return devices;
    });
  }

  static Future<List<String>> deviceNames() {
    return fetchDescriptor().then((descriptor) {
      return descriptor['devices'].map((device) => device['name']).toList();
    });
  }

  static Future<manifest.Manifest> fetchManifest() {
    return http.get("http://git.directcode.org/neo/manifest/raw/HEAD/default.xml").then((response) {
      return manifest.Manifest.parse(response.body);
    });
  }

  static void onBuildStarted(Map<String, dynamic> build) {
    String displayName = build['buildFullName'].replaceAll("neo :: ", "");
    String device = displayName.replaceAll(" ", "_").toLowerCase();
    List<String> subscribers = storage.getList("neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}", defaultValue: []);

    for (var subscriber in subscribers) {
      var split = subscriber.split(":");
      var network = split[0];
      var user = split[1];
      bot.sendMessage(network, user, "${Color.BLUE}[${Color.RESET}neo${Color.BLUE}]${Color.RESET} Build Started for the ${displayName}.");
    }
  }

  static void onBuildFinished(Map<String, dynamic> build) {
    String displayName = build['buildFullName'].replaceAll("neo :: ", "");
    String device = displayName.replaceAll(" ", "_").toLowerCase();
    List<String> subscribers = storage.getList("neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}", defaultValue: []);

    for (var subscriber in subscribers) {
      var split = subscriber.split(":");
      var network = split[0];
      var user = split[1];
      bot.sendMessage(network, user, "${Color.BLUE}[${Color.RESET}neo${Color.BLUE}]${Color.RESET} Build Finished with a status of ${build['buildStatus']} for the ${displayName}.");
    }
  }

  static Future<String> guessDeviceName(String input) {
    return deviceNames().then((names) {
      for (var name in names) {
        if (input.trim().toLowerCase() == name.trim().toLowerCase()) {
          return name;
        }
      }
      return null;
    });
  }

  static void handleCommand(CustomCommandEvent event) {
    var _args = new List<String>.from(event.args);

    if (_args.isEmpty) {
      event.reply("Usage: neo <command> [args]", prefixContent: "neo");
      return;
    }
    var cmd = _args.removeAt(0);
    var cmds = ["subscribe", "unsubscribe", "subscriptions", "devices", "device", "projects", "project-exists", "project", "project-count", "my-issues", "issue", "issue-count"]..sort();
    var args = _args;

    switch (cmd) {
      case "subscribe":
        if (args.isEmpty) {
          event.reply("Usage: neo subscribe <device>", prefixContent: "neo");
          return;
        }
        var input = args.join(" ");

        guessDeviceName(input).then((device) {
          if (device == null) {
            event.reply("Invalid Device. To get a list of devices, please use '\$neo devices'.", prefixContent: "neo");
            return;
          }

          var key = "neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}";
          List<String> subscribers = storage.getList(key, defaultValue: []);
          if (subscribers.contains("${event.network}:${event.user}")) {
            event.reply("You are already subscribed to build notifications for the ${device}.", prefixContent: "neo");
            return;
          }
          subscribers.add("${event.network}:${event.user}");
          storage.setList(key, subscribers);
          event.reply("You have been subscribed to build notifications for the ${device}.", prefixContent: "neo");
        });
        break;
      case "unsubscribe":
        if (args.isEmpty) {
          event.reply("Usage: neo unsubscribe <device>", prefixContent: "neo");
          return;
        }
        var input = args.join(" ");

        guessDeviceName(input).then((device) {
          if (device == null) {
            event.reply("Invalid Device. To get a list of devices, please use '\$neo devices'.", prefixContent: "neo");
            return;
          }

          var key = "neo.device_subscribe.${device.replaceAll(" ", "_").toLowerCase()}";
          List<String> subscribers = storage.getList(key, defaultValue: []);
          if (!subscribers.contains("${event.network}:${event.user}")) {
            event.reply("You are not subscribed to build notifications for the ${device}.", prefixContent: "neo");
            return;
          }
          subscribers.remove("${event.network}:${event.user}");
          storage.setList(key, subscribers);
          event.reply("You are no longer subscribed to build notifications for the ${device}.", prefixContent: "neo");
        });
        break;
      case "subscriptions":
        if (args.isNotEmpty) {
          event.reply("Usage: neo subscriptions", prefixContent: "neo");
          return;
        }
        var subs = storage.keys.where((key) {
          return key.startsWith("neo.device_subscribe.") && storage.getList(key, defaultValue: []).contains(event.network + ":" + event.user);
        }).map((key) => key.replaceAll("neo.device_subscribe.", "").replaceAll("_", " ")).map((key) => key.split(" ").map((it) => it[0].toUpperCase() + it.substring(1)).join(" ")).toList();
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
        var id = args.join(" ");

        deviceInformation().then((devices) {
          for (var device in devices) {
            if (device.name == id || device.codename == id) {
              event.reply("name: ${device.name}, codename: ${device.codename}, manufacturer: ${device.manufacturer}", prefixContent: "neo");
              return;
            }
          }

          event.reply("Invalid Device Identifier '${id}'", prefixContent: "neo");
        });
        break;
      case "project-count":
        fetchManifest().then((manifest) {
          var total = manifest.projects.length;
          var byDefault = manifest.projects.where((project) => !project.groups.contains("notdefault")).length;
          var optional = manifest.projects.where((project) => project.groups.contains("notdefault")).length;
          event.reply("Total: ${total}, Required: ${byDefault}, Optional: ${optional}", prefixContent: "neo");
        });
        break;
      case "project-exists":
        if (args.length != 1) {
          event.reply("Usage: neo project-exists <path>", prefixContent: "neo");
          return;
        }
        var path = args[0];
        fetchManifest().then((manifest) {
          var prj = manifest.projects.firstWhere((project) => project.path == path, orElse: () => null);

          if (prj == null) {
            event.reply("No Project was found at ${path}.", prefixContent: "neo");
            return;
          }

          if (prj.groups.contains("notdefault")) {
            event.reply("Project was found, but it is optional.", prefixContent: "neo");
            return;
          }

          event.reply("Project Found.", prefixContent: "neo");
        });
        break;
      case "issue":
        if (args.length != 1) {
          event.reply("Usage: neo issue <id>", prefixContent: "neo");
        }

        int id;

        try {
          id = int.parse(args[0]);
        } catch (e) {
          event.reply("Invalid Issue ID.", prefixContent: "neo");
          return;
        }

        getIssue(id).then((json) {
          event.replyNotice("Title: ${json["title"]}", prefixContent: "neo");
          event.replyNotice("Created By: ${json["author"]["username"]}", prefixContent: "neo");
          event.replyNotice("Labels: ${json["labels"].join(", ")}", prefixContent: "neo");
          var state = json["state"];
          state = state[0].toUpperCase() + state.substring(1);
          event.replyNotice("State: ${state}", prefixContent: "neo");
          if (json["assignee"] != null) {
            event.replyNotice("Assignee: ${json["assignee"]["username"]}", prefixContent: "neo");
          }
        }).catchError((e) {
          event.reply("Issue Not Found", prefixContent: "neo");
        });
        break;
      case "issue-count":
        getIssues().then((issues) {
          var opened = issues.where((it) => it["state"] == "opened").length;
          var closed = issues.where((it) => it["state"] == "closed").length;
          event.reply("Total: ${issues.length}, Open: ${opened}, Closed: ${closed}", prefixContent: "neo");
        });
        break;
      case "my-issues":
        getIssues().then((issues) {
          var assigned = issues.where((it) => it["assignee"] != null && it["assignee"]["username"] == event.user).toList();
          for (var issue in assigned) {
            event.replyNotice("'${issue["title"]}' (${issue["iid"]}) by ${issue["author"]["username"]}", prefixContent: "neo");
          }

          if (assigned.isEmpty) {
            event.replyNotice("No Issues were found that are assigned to you.", prefixContent: "neo");
          }
        });
        break;
      case "project":
        if (args.length != 1) {
          event.reply("Usage: neo project <path | name>", prefixContent: "neo");
          return;
        }

        var id = args[0];

        fetchManifest().then((manifest) {
          var prj = manifest.projects.firstWhere((project) => project.path == id || project.name == id || project.name.replaceAll(".git", "") == id, orElse: () => null);

          if (prj == null) {
            event.reply("No Project Found.", prefixContent: "neo");
            return;
          }

          var name = prj.name;
          var path = prj.path;
          var optional = prj.groups.contains("notdefault");
          var remote = prj.remote;
          var revision = prj.revision != null ? prj.revision : manifest.defaultSettings.revision;
          var groups = prj.groups;

          event.reply("Name: ${name}, Path: ${path}", prefixContent: "neo");
          event.reply("Remote: ${remote}, Revision: ${revision}", prefixContent: "neo");
          if (groups.isNotEmpty) {
            event.reply("Groups: ${groups.join(", ")}", prefixContent: "neo");
          }
          event.reply("Optional: ${optional}", prefixContent: "neo");
        });
        break;
      case "help":
        event.reply("Commands: ${cmds.join(", ")}", prefixContent: "neo");
        break;
      default:
        event.reply("No Such Command '${cmd}'", prefixContent: "neo");
        break;
    }
  }
}
