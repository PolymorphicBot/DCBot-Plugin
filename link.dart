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
          plugin.send("join", {
            "channel": args["channel"].toString()
          });
        });
        
        networkNode.createAction("Part", params: {
          "channel": ValueType.STRING
        }, execute: (args) {
          plugin.send("join", {
            "channel": args["channel"].toString()
          });
        });
        
        plugin.get("whois", {
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
              plugin.send("part", {
                "network": net,
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
  
  plugin.onShutdown(() {
    link.disconnect().then((_) {
      print("DSLink Disconnected.");
    });
  });
}