// Copyright (c) 2013, Nicholas BIlyk.
// All rights reserved. Use of this source code is governed by an
// Apache 2.0 license that can be found in the LICENSE file.

library test_add_once_performance;

import "package:blix_signals/signals.dart";
import "dart:async";

// Import BenchmarkBase class.
import 'package:benchmark_harness/benchmark_harness.dart';

class SignalAddOnceBenchmark extends BenchmarkBase {
	const SignalAddOnceBenchmark() : super("SignalAddOnceBenchmark");

	static Signal<int> _s;

	void _h0(int i) {}
	void _h1(int i) {}
	void _h2(int i) {}
	void _h3(int i) {}
	void _h4(int i) {}
	void _h5(int i) {}
	void _h6(int i) {}
	void _h7(int i) {}
	void _h8(int i) {}
	void _h9(int i) {}


	static void main() {
		new SignalAddOnceBenchmark().report();
	}

	// The benchmark code.
	void run() {
		_s.addOnce(_h0);
		_s.addOnce(_h1);
		_s.addOnce(_h2);
		_s.addOnce(_h3);
		_s.addOnce(_h4);
		_s.addOnce(_h5);
		_s.addOnce(_h6);
		_s.addOnce(_h7);
		_s.addOnce(_h8);
		_s.addOnce(_h9);
		_s.dispatch(0);
	}

	// Not measured setup code executed prior to the benchmark runs.
	void setup() {
		_s = new Signal<int>();
	}

	// Not measures teardown code executed after the benchark runs.
	void teardown() {}
}


class StreamAddOnceBenchmark extends BenchmarkBase {
	const StreamAddOnceBenchmark() : super("StreamAddOnceBenchmark");

	static StreamController<int> streamController;
	static Stream<int> stream;

	void _h0(int i) {}
	void _h1(int i) {}
	void _h2(int i) {}
	void _h3(int i) {}
	void _h4(int i) {}
	void _h5(int i) {}
	void _h6(int i) {}
	void _h7(int i) {}
	void _h8(int i) {}
	void _h9(int i) {}

	static void main() {
		new StreamAddOnceBenchmark().report();
	}

	// The benchmark code.
	void run() {
		stream.first.then(_h0);
		stream.first.then(_h1);
		stream.first.then(_h2);
		stream.first.then(_h3);
		stream.first.then(_h4);
		stream.first.then(_h5);
		stream.first.then(_h6);
		stream.first.then(_h7);
		stream.first.then(_h8);
		stream.first.then(_h9);
		streamController.add(0);
	}

	// Not measured setup code executed prior to the benchmark runs.
	void setup() {
	 	streamController = new StreamController<int>.broadcast(sync: true);
	 	stream = streamController.stream;
	}

	// Not measures teardown code executed after the benchark runs.
	void teardown() {}
}

main() {
	// Compare signal addOnce to Stream add once equivalent.
	SignalAddOnceBenchmark.main();
	StreamAddOnceBenchmark.main();
}