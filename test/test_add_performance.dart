// Copyright (c) 2013, Nicholas BIlyk.
// All rights reserved. Use of this source code is governed by an
// Apache 2.0 license that can be found in the LICENSE file.

library test_add_performance;

import "package:blix_signals/signals.dart";
import "dart:async";

// Import BenchmarkBase class.
import 'package:benchmark_harness/benchmark_harness.dart';

class SignalAddBenchmark extends BenchmarkBase {
	const SignalAddBenchmark() : super("SignalAddBenchmark");

	static Signal<int> _s;

	static void main() {
		new SignalAddBenchmark().report();
	}

	// The benchmark code.
	void run() {
		var n = 100;
		while (n-- > 0) {
			_s.add((int i) {});
		}
	}

	// Not measured setup code executed prior to the benchmark runs.
	void setup() {
		_s = new Signal<int>();
	}

	// Not measures teardown code executed after the benchark runs.
	void teardown() {}
}


class StreamAddBenchmark extends BenchmarkBase {
	const StreamAddBenchmark() : super("StreamAddBenchmark");

	static StreamController<int> streamController;
	static Stream<int> stream;

	static void main() {
		new StreamAddBenchmark().report();
	}

	// The benchmark code.
	void run() {
		var n = 100;
		while (n-- > 0) {
			stream.listen((int i) {});
		}
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
	// Compare signal addOnce to Stream add + remove.
	SignalAddBenchmark.main();
	StreamAddBenchmark.main();
}