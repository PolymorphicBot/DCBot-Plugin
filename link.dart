part of dcbot.plugin;

DSLink link;

void setupLink() {
  link = new DSLink("DCBot", host: "rnd.iot-dsa.org");
  
  new Future.delayed(new Duration(seconds: 10), () {
    bot.getNetworks().then((networks) {
      for (var net in networks) {
        var networkNode = link.createRootNode(net);
        networkNode.createAction("SendMessage", params: {
          "target": ValueType.STRING,
          "message": ValueType.STRING
        }, execute: (args) {
          bot.message(net, args['target'].toString(), args['message'].toString());
        });
        
        networkNode.createAction("Join", params: {
          "channel": ValueType.STRING
        }, execute: (args) {
          bot.send("join", {
            "channel": args["channel"].toString()
          });
        });
        
        networkNode.createAction("Part", params: {
          "channel": ValueType.STRING
        }, execute: (args) {
          bot.send("join", {
            "channel": args["channel"].toString()
          });
        });
        
        bot.get("whois", {
          "network": net,
          "user": "DirectCodeBot"
        }).then((data) {
          for (var channel in data["channels"]) {
            var channelNode = networkNode.createChild(channel);
            channelNode.createAction("SendMessage", params: {
              "message": ValueType.STRING
            }, execute: (args) {
              bot.message(net, channel, args["message"].toString());
            });
            
            channelNode.createAction("Part", execute: (args) {
              bot.send("part", {
                "channel": channel
              });
            });
          }
        });
      }
    });
  });
  
  link.connect().then((_) {
    print("DSLink Connected.");
  });
  
  eventManager.onShutdown(() {
    link.disconnect().then((_) {
      print("DSLink Disconnected.");
    });
  });
}