part of dcbot.plugin;

class GitLab {
  static void initialize() {
    router.serve("/gitlab/hook", method: "POST").listen((request) {
      var response = request.response;
      HttpBodyHandler.processRequest(request).then((body) {
        Map<String, dynamic> json = body.body;

        handleHookEvent(json);

        response.write("");

        return response.close();
      });
    });
  }

  static void handleHookEvent(Map<String, dynamic> input) {
    var ref = input['ref'];

    if (ref.startsWith("refs/heads/")) {
      ref = ref.replaceFirst("refs/heads/", "");
    }

    var user = input['user_name'];
    var repositoryName = input['repository']['name'];

    var channel = "#directcode";

    var commits = input['commits'];
    
    bot.message("EsperNet", channel, "[${repositoryName}] ${user} pushed to branch ${ref}:");

    for (var commit in commits) {
      bot.message("EsperNet", channel, "${commit['author']['name']}: ${commit['message']}");}
  }
}