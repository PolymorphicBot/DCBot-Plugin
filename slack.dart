part of dcbot.plugin;

void handleSlackRequest(HttpRequest request) {
  var response = request.response;
  HttpBodyHandler.processRequest(request).then((body) {
    Map<String, String> form = body.body;
    
    handleSlackMessage(form);
    
    response.write("");
    
    return response.close();
  });
}

void handleSlackMessage(Map<String, String> data) {
  String user = data['user_name'];
  String message = data['text'];
  print("[DCBot] Slack: ${data}");
  if (user == "IFTTT") {
    bot.message("EsperNet", "#directcode", "${fancyPrefix("IFTTT")} ${message}");
  }
}

void setupSlack() {
  router.serve("/slack", method: "POST").listen(handleSlackRequest);
}
