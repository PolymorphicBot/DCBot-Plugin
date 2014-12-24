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