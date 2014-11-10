import "markov.dart";

void main() {
  var chain = new MarkovChain();
  chain.load();
  
  void test(String line) {
    var reply = chain.reply(line, "Alex", "DirectCodeBot");
    print("<DirectCodeBot> ${reply}");
  }
  
  test("Hello");
  test("Welcome World");
}