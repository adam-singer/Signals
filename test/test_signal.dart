library test_signal;

import "package:unittest/unittest.dart";
import "package:signals/signals.dart";


void main() {
	group("Signal -", () {

		test("add", () {
			int c = 0;
			Signal<String> signal = new Signal<String>();
			signal.add(
				(String s) => c++
			);
			signal.dispatch("Hi");
			expect(c, 1);
			signal.dispatch("Hi");
			expect(c, 2);
			signal.add(
				(String s) => c++
			);
			signal.dispatch("Hi");
			expect(c, 4);
		});

		test("addDuplicate", () {
			int c = 0;
			Signal<String> signal = new Signal<String>();

			Function h = (String s) => c++;
			Function j = (String s) => c++;
			expect(signal.add(h), true);
			expect(signal.add(h), false);
			expect(signal.add(h), false);
			signal.dispatch("Hi");
			expect(c, 1);
			expect(signal.add(j), true);
			expect(signal.add(h), false);
			signal.dispatch("Hi");
			expect(c, 3);
			expect(signal.add(j), false);
			expect(signal.add(h), false);
			expect(signal.add(j), false);
			expect(signal.add(h), false);
			signal.add(j);
			signal.dispatch("Hi");
			expect(c, 5);
			expect(signal.remove(j), true);
			expect(signal.remove(j), false);
			expect(signal.add(h), false);
			expect(signal.add(h), false);
			signal.dispatch("Hi");
			expect(c, 6);

			signal.dispatch("Hi");
			expect(c, 4);
		});

		test("addOnce", () {
			int c = 0;
			Signal<String> signal = new Signal<String>();
			signal.add(
				(String s) => c++, true
			);
			signal.dispatch("Hi");
			expect(c, 1);
			signal.dispatch("Hi");
			expect(c, 1);
			signal.add(
				(String s) => c++, true
			);
			signal.dispatch("Hi");
			expect(c, 2);
		});

		test("testDestroy", () {
			Signal<String> signal = new Signal<String>();

			signal.add((String s) => print(s));
			signal.dispatch("Hi");
			signal.destroy();

			try {
				signal.dispatch("Should fail.");
				fail("The signal should have thrown an error dispatching after destruction.");
			} catch (e) {
			}

		});

	});
}