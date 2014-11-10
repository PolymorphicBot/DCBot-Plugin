import "markov.dart";

void main() {
  var chain = new MarkovChain();
  chain.load();
  
  void test(String line) {
    var reply = chain.reply(line, "Alex", "DirectCodeBot");
    print("${line} => ${reply}");
  }
  
  print(chain.generateWordStats(["i", "have"]));
  
  test("i have");
}
