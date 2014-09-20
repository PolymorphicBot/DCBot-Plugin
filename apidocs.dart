part of dcbot.plugin;

class APIDocs {
  static const String LIBRARY_LIST_URL = "https://api.dartlang.org/apidocs/channels/stable/docs/library_list.json";
  
  static Map<String, String> index = {};
  
  static void init() {
    http.get("https://api.dartlang.org/apidocs/channels/stable/docs/index.json").then((response) {
      index = JSON.decode(response.body);
    });
  }
  
  static void handleWhatIsCmd(CustomCommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: ${event.command} <id>", prefix: false);
      return;
    }
    
    String id = event.args.join(" ");
    
    if (index.containsKey(id)) {
      event.reply("> Type: ${index[id]}", prefix: false);
    } else {
      event.reply("> ID not found.", prefix: false);
    }
  }
}