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

  test('enumToIndexNameString basic test', () {
    TestEnum t0 = TestEnum.test0;
    String expectedOutput = '0.test0';
    String actualOutput = enumToIndexNameString(t0);

    expect(actualOutput, expectedOutput);

    TestEnum t1 = TestEnum.test1;
    expectedOutput = '1.test1';
    actualOutput = enumToIndexNameString(t1);

    expect(actualOutput, expectedOutput);
  });

  test('enumFromIndexNameString basic test', () {
    String input = '0.test0';
    TestEnum actualOutput = enumFromIndexNameString(input, TestEnum.values);
    TestEnum expectedOutput = TestEnum.test0;

    expect(actualOutput, expectedOutput);
  });

  test('enumFromIndexNameString throws ArgumentError for invalid input', () {
    expect(
      () => enumFromIndexNameString<TestEnum>('invalid', TestEnum.values),
      throwsA(isA<ArgumentError>()),
    );
  });
}

enum TestEnum { test0, test1, test2 }
