import 'package:flutter_test/flutter_test.dart';

import 'package:get_together/utils.dart';

void main() {
  test('_rollContents basic tests', () {
    List<int> input = [1, 2, 3, 4, 5];
    List<int> expectedOutput = [5, 1, 2, 3, 4];
    List<int> actualOutput = rollList(input, -1);
    expect(actualOutput, expectedOutput);

    List<int> expectedOutputRollBack1 = [2, 3, 4, 5, 1];
    actualOutput = rollList(input, 1);
    expect(actualOutput, expectedOutputRollBack1);
  });
}
