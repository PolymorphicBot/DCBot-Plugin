part of dcbot.plugin;

class ServiceEventBus {
  final String url;
  final String token;

  List<String> _queue = [];
  List<String> subscriptions = [];
  
  WebSocket _socket;

  StreamController<Map<String, dynamic>> _controller = new StreamController();
  Stream<Map<String, dynamic>> _stream;

  Completer _connectCompleter;
  
  ServiceEventBus(this.url, this.token) {
    _stream = _controller.stream.asBroadcastStream();
    _init();
  }

  void _init() {
    onMessage("connect").listen((event) {
      sendMessage("connect", {
        "token": token
      });
    });
    
    onMessage("ready").listen((event) {
      while (_queue.isNotEmpty) {
        _socket.add(_queue.removeAt(0));
      }
      
      if (_connectCompleter != null) {
        _connectCompleter.complete();
      }
    });
  }

  Future connect({bool reconnect: true}) {
    _connectCompleter = new Completer();
    WebSocket.connect(url).then((socket) {
      _socket = socket;

      socket.listen((data) {
        var json = JSON.decode(data);
        _controller.add(json);
      });
      
      socket.done.then((_) {
        _socket = null;
        if (reconnect) {
          return connect();
        }
      });
    }).catchError((e) {
      print("Failed to Connect to the Event Bus.");
    });
    return _connectCompleter.future;
  }

  void _sendJSON(object) {
    if (_socket == null) {
      _queue.add(JSON.encode(object));
    } else {
      _socket.add(JSON.encode(object));
    }
  }

  Stream<Map<String, dynamic>> onMessage(String type) {
    return _stream.where((event) => event['type'] == type);
  }

  Stream<Map<String, dynamic>> on(String event) {
    return onMessage("event").where((it) => it['event'] == event).map((it) {
      return it['data'];
    });
  }

  void sendMessage(String type, Map params) {
    _sendJSON({
      "type": type
    }..addAll(params));
  }

  void subscribe(e) {
    var events = e is String ? [e] : e;
    for (var event in events) {
      sendMessage("register", {
        "event": event
      });
    }
  }

  void unsubscribe(e) {
    var events = e is String ? [e] : e;
    for (var event in events) {
      sendMessage("unregister", {
        "event": event
      });
    }
  }

  void emit(String event, Map data) {
    sendMessage("emit", {
      "event": event,
      "data": data
    });
  }
}

ServiceEventBus eventBus;

void setupServices() {
  eventBus = new ServiceEventBus("ws://${servicesUrl}/events/ws", servicesToken);
  
  eventBus.connect().then((_) {
    print("Connected to Event Bus");
  
    eventBus.subscribe([
      "members.added",
      "members.removed",
      "github.hook",
      "gitlab.hook",
      "neo.teamcity.hook",
      "irc.send.message",
      "irc.send.raw",
      "irc.get.networks"
    ]);

    eventBus.on("members.added").listen((event) {
      bot.sendMessage("EsperNet", "#directcode", "${fancyPrefix("DirectCode")} ${event['name']} is now a member");
    });

    eventBus.on("members.removed").listen((event) {
      bot.sendMessage("EsperNet", "#directcode", "${fancyPrefix("DirectCode")} ${event['name']} is no longer a member");
    });
    
    eventBus.on("irc.send.message").listen((event) {
      var network = event['network'];
      var target = event['target'];
      var msg = event['message'];
      bot.sendMessage(network, target, msg);
    });
    
    eventBus.on("irc.send.raw").listen((event) {
      var network = event['network'];
      var line = event['line'];
      bot.sendRawLine(network, line);
    });
    
    eventBus.on("irc.get.networks").listen((event) {
      bot.getNetworks().then((networks) {
        eventBus.emit("irc.networks", {
          "networks": networks
        });
      });
    });
    
    plugin.on("join").listen((event) {
      eventBus.emit("irc.user.join", event);
    });
    
    plugin.on("part").listen((event) {
      eventBus.emit("irc.user.part", event);
    });
  });
}

const String servicesUrl = "services.directcode.org:8090";

String servicesToken;

void handleServicesCommand(CustomCommandEvent event) {
  switch (event.command) {
    case "list-members":
      http.get("http://" + servicesUrl + "/api/members/list").then((response) {
        var json = JSON.decode(response.body);

        var out = json.map((it) => it['name']).join(", ");

        event.reply("Members: ${out}", prefixContent: "DirectCode");
      });
      break;
  }
  
  eventBus.emit("irc.command", {
    "network": event.network,
    "channel": event.channel,
    "user": event.user,
    "message": event.message,
    "command": event.command,
    "args": event.args
  });
}
