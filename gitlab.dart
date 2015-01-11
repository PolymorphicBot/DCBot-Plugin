part of dcbot.plugin;

class NeoGitLab {
  static void initialize() {
    eventBus.on("neo.gitlab.hook").listen(handleHookEvent);
  }

  static void handleHookEvent(Map<String, dynamic> input) {
    print("Got GitLab Hook Event: ${input}");
    if (input["commits"] == null) {
      return;
    }
    
    var ref = input['ref'];

    if (ref.startsWith("refs/heads/")) {
      ref = ref.replaceFirst("refs/heads/", "");
    }

    var user = input['user_name'];
    
    if (user == "DirectCodeBot" || user == "Room Service" || user == "DirectCode Bot") {
      return;
    }
    
    var repositoryName = input['repository']['name'].replaceAll("_", "/");
    var channel = "#directcode";
    var count = input["total_commits_count"];
    List<Map<String, dynamic>> commits = input['commits'].take(5).toList();
    
    if (count <= 0) return;
    
    bot.sendMessage("EsperNet", channel, "[${repositoryName}] ${user} pushed ${count} ${count == 1 ? "commit" : "commits"} to branch ${ref}:");

    for (var commit in commits) {
      bot.sendMessage("EsperNet", channel, "${commit['author']['name']}: ${commit['message']}");
    }
  }
}