part of dcbot.plugin;

HttpServer server;
Router router;

Future setupServer() {
  return HttpServer.bind("0.0.0.0", 8030).then((_server) {
    server = _server;
    
    router = new Router(server);
    
    router.defaultStream.listen((request) => send404(request));
  });
}
