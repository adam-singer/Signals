// Copyright (c) 2013, Nicholas BIlyk.
// All rights reserved. Use of this source code is governed by an
// Apache 2.0 license that can be found in the LICENSE file.

library test_signal;

import "package:unittest/unittest.dart";
import "package:blix_signals/signals.dart";

void main() {

	group("Signal -", () {

		test("added handlers are invoked on dispatch", () {
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

		test("ignores duplicate adds and removes", () {
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
			expect(signal.add(j), false);
			signal.dispatch("Hi");
			expect(c, 5);
			expect(signal.remove(j), true);
			expect(signal.remove(j), false);
			expect(signal.add(h), false);
			expect(signal.add(h), false);
			signal.dispatch("Hi");
			expect(c, 6);
			expect(signal.remove(h), true);
			expect(signal.remove(h), false);
			expect(signal.remove(j), false);
			signal.dispatch("Hi");
			expect(c, 6);
		});

		test("errs when adding mismatched handlers", () {
			Signal<String> signal = new Signal<String>();
			Function f = (int i) => i++; // Intentionally set as a dynamic Function to avoid compiler warnings.
			expect(() => signal.add(f), throws, reason: "Adding a handler with a mismatching method signature should throw an error on add()");
		});

		test("the add once flag removes the handler after a dispatch", () {
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

		test("destroy removes all handlers and prevents new calls", () {
			int c = 0;
			Signal<String> signal = new Signal<String>();
			signal.add((String s) => c++);
			signal.dispatch("Hi");
			signal.destroy();

			expect(() => signal.dispatch("Should fail."), throwsStateError, reason: "The signal should have thrown an error calling dispatch() after destruction.");
			expect(() => signal.add((String s) => c++), throwsStateError, reason: "The signal should have thrown an error calling add() after destruction.");
			expect(() => signal.remove((String s) => c++), throwsStateError, reason: "The signal should have thrown an error calling remove() after destruction.");
			expect(() => signal.clear(), throwsStateError, reason: "The signal should have thrown an error calling clear() after destruction.");

		});

		test("clear removes all handlers", () {
			int c = 0;
			Function h = (String s) => c++;
			Function j = (String s) => c++;
			Signal<String> signal = new Signal<String>();
			signal.add(h);
			signal.add(j);
			signal.dispatch("Hi");
			expect(c, 2);
			signal.clear();
			signal.dispatch("Hi");
			expect(c, 2);
			signal.add(h);
			signal.dispatch("Hi");
			expect(c, 3);
			signal.clear();
			signal.dispatch("Hi");
			expect(c, 3);
		});

		test("isEmpty is true when the signal has no handlers", () {
			Signal<int> signal = new Signal<int>();
			expect(signal.isEmpty, true);
			signal.add((int c) => c++, true);
			expect(signal.isEmpty, false);
			signal.dispatch(1);
			expect(signal.isEmpty, true);
			signal.add((int c) => c++);
			signal.add((int c) => c++);
			signal.add((int c) => c++);
			expect(signal.isEmpty, false);
			signal.clear();
			expect(signal.isEmpty, true);
		});

		test("the handlers are dispatched in the order they're added", () {
			var order = <int>[];
			Signal<int> signal = new Signal<int>();
			signal.add((int c) => order.add(0));
			signal.add((int c) => order.add(1));
			signal.add((int c) => order.add(2));
			Function f3 = (int c) => order.add(3);
			signal.add(f3);
			signal.add((int c) => order.add(4));
			signal.add((int c) => order.add(5));
			signal.add((int c) => order.add(6));

			signal.dispatch(0);
			expect(order, <int>[0, 1, 2, 3, 4, 5, 6]);

			// Ensure a remove doesn't affect order.
			signal.remove(f3);
			order.clear();
			signal.dispatch(0);
			expect(order, <int>[0, 1, 2, 4, 5, 6]);
		});

		group("concurrent modifications -", () {
			test("adding handlers during a dispatch will cause those handlers to be invoked on the next dispatch", () {
				int c = 0;
				var incC = (int i) => c++;
				Signal<int> signal = new Signal<int>();

				bool isAdded = signal.add((int i) {
					expect(signal.add(incC), true);
					expect(signal.add(incC), false);
				}, true);
				expect(isAdded, true);

				expect(signal.length, 1);
				signal.dispatch(0); // The first handler will add incC().
				expect(signal.length, 1); // The first handler removed, incC added
				expect(c, 0); // Expect incC not to be called on the first dispatch.
				signal.dispatch(0);
				expect(c, 1);
			});

			test("removing handlers during a dispatch will cause those handlers not to be invoked on the next dispatch", () {
				int c = 0;
				var incC = (int i) => c++;
				Signal<int> signal = new Signal<int>();
				signal.add((int i) {
					signal.remove(incC);
				}, true);
				signal.add(incC);
				signal.dispatch(0);
				expect(c, 1); // Expect that even though the first handler is called first and removes the incC handler, the incC handler should still be called.
				c = 0;
				signal.dispatch(0);
				expect(c, 0); // The incC should not be called on the second dispatch because it was removed during the first.
			});

			test("removing an isOnce handler during dispatch", () {
				int c = 0;
				Signal<int> signal = new Signal<int>();
				var onceF;
				onceF = (int i) {
					signal.remove(onceF);
					c++;
				};
				signal.add(onceF, true);
				signal.dispatch(0);
				expect(c, 1);
				signal.dispatch(0);
				expect(c, 1);
			});

			test("clearing during dispatch", () {
				int c = 0;
				Signal<int> signal = new Signal<int>();

				signal.add((int i) => signal.clear());
				var incC = (int i) {
					c++;
				};
				signal.add(incC);
				signal.dispatch(0); // Will call a handler with signal.clear()
				expect(c, 1); // Should finish the dispatch.
				signal.dispatch(0);
				expect(c, 1); // incC should have been cleared.
			});

			test("removing an isOnce handler during dispatch", () {
				int c = 0;
				Signal<int> signal = new Signal<int>();
				var incC = (int i) {
					c++;
				};
				signal.add((int i) => signal.remove(incC));
				signal.add(incC, true);

				signal.dispatch(0); // Will call a handler with signal.clear()
				expect(c, 1); // Should finish the dispatch.
				signal.dispatch(0);
				expect(c, 1); // incC should have been cleared.
			});

		});


	});
}