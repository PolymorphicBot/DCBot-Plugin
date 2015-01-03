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
    
    bot.sendMessage("EsperNet", channel, "[${repositoryName}] ${user} pushed to branch ${ref}:");
    bot.sendMessage("DCNET", channel, "[${repositoryName}] ${user} pushed to branch ${ref}:");

    for (var commit in commits) {
      bot.sendMessage("EsperNet", channel, "${commit['author']['name']}: ${commit['message']}");
      bot.sendMessage("DCNET", channel, "${commit['author']['name']}: ${commit['message']}");
    }
  }
}