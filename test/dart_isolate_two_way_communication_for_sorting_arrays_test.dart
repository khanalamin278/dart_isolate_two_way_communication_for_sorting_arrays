import 'package:dart_isolate_two_way_communication_for_sorting_arrays/dart_isolate_two_way_communication_for_sorting_arrays.dart';
import 'package:test/test.dart';

void main() {
  test('sortArrayInIsolate sorts arrays with two-way communication', () async {
    var sortingIsolate = await setupSortingIsolate();

    expect(await sortingIsolate.sendAndReceive([5, 3, 1, 4, 2]),
        equals([1, 2, 3, 4, 5]));
    expect(await sortingIsolate.sendAndReceive([10, 20, 15, 5, 25]),
        equals([5, 10, 15, 20, 25]));

    await sortingIsolate.shutdown();
  });
}
