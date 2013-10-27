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
		new SignalAddBenchmark().report();
	}

	// The benchmark code.
	void run() {
		_s.add(_h0);
		_s.add(_h1);
		_s.add(_h2);
		_s.add(_h3);
		_s.add(_h4);
		_s.add(_h5);
		_s.add(_h6);
		_s.add(_h7);
		_s.add(_h8);
		_s.add(_h9);
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
		new StreamAddBenchmark().report();
	}

	// The benchmark code.
	void run() {
		stream.listen(_h0);
		stream.listen(_h1);
		stream.listen(_h2);
		stream.listen(_h3);
		stream.listen(_h4);
		stream.listen(_h5);
		stream.listen(_h6);
		stream.listen(_h7);
		stream.listen(_h8);
		stream.listen(_h9);
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