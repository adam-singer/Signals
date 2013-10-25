// Copyright (c) 2013, Nicholas BIlyk.
// All rights reserved. Use of this source code is governed by an
// Apache 2.0 license that can be found in the LICENSE file.

library test_signal;

import "package:unittest/unittest.dart";
import "package:blix_signals/signals.dart";

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

		test("addBadType", () {
			Signal<String> signal = new Signal<String>();
			Function f = (int i) => i++; // Intentionally set as a dynamic Function to avoid compiler warnings.
			expect(() => signal.add(f), throws, reason: "Adding a handler with a mismatching method signature should throw an error on add()");
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
			int c = 0;
			Signal<String> signal = new Signal<String>();
			signal.add((String s) => c++);
			signal.dispatch("Hi");
			signal.destroy();

			expect(() => signal.dispatch("Should fail."), throws, reason: "The signal should have thrown an error calling dispatch() after destruction.");
			expect(() => signal.add((String s) => c++), throws, reason: "The signal should have thrown an error calling add() after destruction.");
			expect(() => signal.remove((String s) => c++), throws, reason: "The signal should have thrown an error calling remove() after destruction.");
			expect(() => signal.removeAll(), throws, reason: "The signal should have thrown an error calling removeAll() after destruction.");

		});

		test("removeAll", () {
			int c = 0;
			Function h = (String s) => c++;
			Function j = (String s) => c++;
			Signal<String> signal = new Signal<String>();
			signal.add(h);
			signal.add(j);
			signal.dispatch("Hi");
			expect(c, 2);
			signal.removeAll();
			signal.dispatch("Hi");
			expect(c, 2);
			signal.add(h);
			signal.dispatch("Hi");
			expect(c, 3);
			signal.removeAll();
			signal.dispatch("Hi");
			expect(c, 3);
		});

	});
}