import 'package:flutter_test/flutter_test.dart';

import 'package:onebus/data/mock_data.dart';

void main() {
  test('integration stops are served by several lines', () {
    expect(MockData.stop('s17').lineIds, containsAll(['l214', 'l302', 'l057']));
    expect(MockData.stop('s18').lineIds, containsAll(['l214', 'l108']));
  });
}
