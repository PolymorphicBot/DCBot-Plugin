part of dcbot.plugin;

class GitLab {
  static void initialize() {
    eventBus.on("gitlab.hook").listen(handleHookEvent);
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