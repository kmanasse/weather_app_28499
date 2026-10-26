// ignore_for_file: avoid_print

Future<String> orderBrochette() async {
  await Future.delayed(const Duration(seconds: 3));
  return 'Your brochette is ready';
}

Future<String> orderDrink() async {
  await Future.delayed(const Duration(seconds: 1));
  return 'Your Fanta is ready';
}

void main() async {
  final watch = Stopwatch()..start();
  print('1. You order a brochette and a Fanta');
  // Start both before awaiting either one, so they run at the same time.
  final order = orderBrochette();
  final drink = orderDrink();
  print('2. While they are prepared, you chat with your friends');
  final food = await order;
  final fanta = await drink;
  print('3. $food');
  print('4. $fanta');
  print('5. You eat');
  print(
    'Took ${watch.elapsed.inSeconds} seconds: 3, not 4, because both started together.',
  );
}
