part of dcbot.plugin;

void setupNeo() {
  router.serve("/teamcity/neo", method: "POST").listen((request) {
    return handleNeoTeamCityHook(request);
  });
}

Future handleNeoTeamCityHook(HttpRequest request) {
  return HttpBodyHandler.processRequest(request).then((body) {
    Map<String, dynamic> json = body.body;
    print("TeamCity Data: ${json}");
  });
}