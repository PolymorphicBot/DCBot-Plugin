part of dcbot.plugin;

class NeoGitLab {
  static Map<String, String> reponames = {
    "packages/apps/sea": "Sea",
    "packages/apps/settings": "Settings",
    "packages/apps/deskclock": "Clock",
    "frameworks/base": "Base Framework",
    "frameworks/native": "Native Framework",
    "packages/apps/launcher3": "Launcher3",
    "packages/apps/reef": "Reef"
  };
  
  static void initialize() {
    eventBus.on("neo.gitlab.hook").listen(handleHookEvent);
  }
  
  static void notify(String message) {
    bot.sendMessage("Freenode", "#NeoAndroid", message);
  }

  static void handleHookEvent(Map<String, dynamic> input) {
    if (input["commits"] != null) {
      var ref = input['ref'];
      var count = input["total_commits_count"];

      if (ref.startsWith("refs/heads/")) {
        ref = ref.replaceFirst("refs/heads/", "");
      }
      
      var repositoryName = input['repository']['name'].replaceAll("_", "/");
      
      if (reponames.containsKey(repositoryName)) {
        repositoryName = reponames[repositoryName];
      }

      var user = input['user_name'];
      
      if (user == "DirectCodeBot" || user == "Room Service" || user == "DirectCode Bot") {
        if (count >= 30) {
          notify("[${Color.BLUE}neo${Color.RESET}] Imported ${repositoryName}");
        }
      } else {
        notify("[${Color.BLUE}neo${Color.RESET}] ${user} pushed ${count} ${count == 1 ? "commit" : "commits"} to ${repositoryName}");
      }
    } else if (input["object_kind"] == "issue" && input["object_attributes"]["project_id"] == 34) {
      var name = input["user"]["name"];
      var attr = input["object_attributes"];
      var id = attr["iid"];
      var title = attr["title"];
      var action = attr["action"];
      var friendlyAction = {
        "open": "opened",
        "close": "closed",
        "reopen": "reopened"
      }[action];
      if (friendlyAction == null) friendlyAction = action;
      
      notify("[${Color.BLUE}neo${Color.RESET}] ${name} ${action} issue ${id} (${title})");
    }
  }
}