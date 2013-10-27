// Copyright (c) 2013, Nicholas BIlyk.
// All rights reserved. Use of this source code is governed by an
// Apache 2.0 license that can be found in the LICENSE file.

part of blix_signals;

/**
 * A type definition for a callback.
 */
typedef Handler<T>(T param);

/**
 * Signals are a light-weight, strongly-typed way to implement the observer pattern. They allow you
 * to explicitly define the messages your objects provide, without relying on metadata or documentation.
 *
 * The Signal object at a basic level is a list of methods to be invoked when the Signal is dispatched.
 *
 * Usage Example:
 *
 *     import 'package:blix_signals/signals.dart';
 *
 *     class MilkEvent {
 *     	num amount;
 *     	num duration;
 *     	MilkEvent(this.amount, this.duration);
 *     }
 *
 *     abstract class IMilkable {
 *     	ISignal<MilkEvent> get milked;
 *     }
 *
 *     class Cow implements IMilkable {
 *     	Signal<MilkEvent> _milked = new Signal<MilkEvent>();
 *
 *     	ISignal<MilkEvent> get milked => _milked;
 *
 *     	void milk() {
 *     		if (_milked.isNotEmpty) {
 *     			_milked.dispatch(new MilkEvent(1, 1));
 *     		}
 *     	}
 *     }
 *
 *     class DeliveryPerson {
 *     	void watchMilkable(IMilkable milkable) {
 *     		milkable.milked.add((MilkEvent e) => fillBottle(e.amount));
 *     	}
 *
 *     	void fillBottle(int amount) {
 *     		print("Added ${amount} milk");
 *     	}
 *     }
 *
 *     void main() {
 *     	var cow = new Cow();
 *     	var deliveryPerson = new DeliveryPerson();
 *     	deliveryPerson.watchMilkable(cow);
 *     	cow.milk(); // added 1 milk
 *     }
 *
 * Three conventions should be pointed out:
 *
 * 1. The signal is described in past tense.
 *
 * 2. The dispatch is surrounded by an [isNotEmpty] check.  This is only important for performance if the message
 * requires work to be done.  That is, if the message requires a new object to be created, it is best to
 * optimize for the case if there are no handlers.
 *
 * 3. The exposed interface is using ISignal instead of Signal. The ISignal interface does not expose the
 * dispatch(T) function. This is because it's generally a bad practice to broadcast a message on behalf of
 * another object.
 *
 */
abstract class ISignal<T> {

	/**
	 * Adds a handler to the signal. This handler should accept one and only one argument, of the same type the
	 * Signal was constructed as.
	 *
	 * If the signal is currently dispatching, the added handler will not be dispatched until the next dispatch call.
	 *
	 * e.g.
	 * 	Signal<String> signal = new Signal<String>();
	 * 	signal.add((String str) => print(str));
	 *
	 * @param handler The callback that will be invoked when dispatch() is called on the signal.
	 * @param isOnce A flag, where if true, will cause the handler to be removed immediately after the next dispatch.
	 * @return Returns true if the handler is added, or false if the handler was already added.
	 *
	 * Special case:
	 * If a handler is added with isOnce = true, and the same handler is added again with isOnce = false, the second
	 * add will be ignored. Handlers are tracked only by the method, and not by the isOnce flag.
	 * If you are intending to change a once handler to a repeated handler or visa versa, first remove the handler,
	 * then re-add.
	 *
	*/
	void add(Handler<T> handler, [bool isOnce = false]);

	/**
	 * A convenience method which calls add() with the addOnce parameter set to true.
	 * @see [add]
	 */
	void addOnce(Handler<T> handler);

	/**
	 * Removes the given handler from the list.
	 *
	 * This call is not blocked during a dispatch.
	 */
	void remove(Handler<T> handler);

	/**
	 * Returns true if the handler is currently in the list.
	 */
	bool contains(Handler<T> handler);


	/**
	 * Removes all handlers from the list.
	 */
	void clear();

	/**
	 * Returns true if the signal has no handlers.
	 */
	bool get isEmpty;

	/**
	 * Returns true if the signal has handlers.
	 *
	 * This is particularly useful for optimizing whether work needs to be done before dispatch.
	 * e.g.
	 * 	if (mySignal.isNotEmpty) {
	 * 		Event e = new Event(e);
	 * 		mySignal.dispatch(e);
	 * 	}
	 */
	bool get isNotEmpty;

	/**
	 * Destroys the signal, removing all handlers.
	 * If any operations are acted on this signal after destruction, a StateError is thrown.
	 */
	void destroy();
}

abstract class IDispatcher<T> {

	/**
	 * Dispatches the dispatcher, invoking every added handler.
	 */
	void dispatch(T);
}

abstract class _LinkedListEntry<T extends _LinkedListEntry> {
	T previous;
	T next;
}

/**
 * A private class used for handler entries in the Signal's linked lists.
 */
class _HandlerEntry<T> implements _LinkedListEntry<_HandlerEntry<T>> {

	final Handler<T> handler;
	final bool isOnce;

	_HandlerEntry<T> previous;
	_HandlerEntry<T> next;

	_HandlerEntry(this.handler, this.isOnce);
}


/**
 * An optimized linked list specifically for signals.
 */
class _SimpleLinkedList<T extends _LinkedListEntry> {

	T head;
	T tail;

	void add(T entry) {
		if (head == null) {
			head = entry;
			tail = entry;
		} else {
			tail.next = entry;
			entry.previous = tail;
			tail = entry;
		}
	}

	void remove(T entry) {
		if (entry.previous != null) entry.previous.next = entry.next;
		if (entry.next != null) entry.next.previous = entry.previous;
		if (entry == head) {
			head = entry.next;
		}
		if (entry == tail) {
			tail = entry.previous;
		}
	}

	void clear() {
		head = null;
		tail = null;
	}
}

class _PendingCall implements _LinkedListEntry<_PendingCall> {

	_LinkedListEntry<_PendingCall> previous;
	_LinkedListEntry<_PendingCall> next;

	Function method;
	List args;

	_PendingCall(this.method, this.args);

	void invoke() {
		Function.apply(method, args);
	}
}



/**
 * The basic implementation of [ISignal]. Refer to the [ISignal] documentation for the overview of
 * Signals and their use.
 */
class Signal<T> implements ISignal<T>, IDispatcher<T> {

	bool _enabled = true;
	bool _isDispatching = false;

	final _SimpleLinkedList<_HandlerEntry<T>> _handlers = new _SimpleLinkedList<_HandlerEntry<T>>();
	final _SimpleLinkedList<_PendingCall> _pendingCalls = new _SimpleLinkedList<_PendingCall>();
	int _length = 0;

	/**
	 * Creates a new Signal object.
	 */
	Signal() {
	}

	void add(Handler<T> handler, [bool isOnce = false]) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		_HandlerEntry<T> entry = new _HandlerEntry<T>(handler, isOnce);
		_length++;

		if (_isDispatching) {
			_pendingCalls.add(new _PendingCall(_handlers.add, [entry]));
		} else {
			_handlers.add(entry);
		}
	}


	void addOnce(Handler<T> handler) {
		add(handler, true);
	}

	bool remove(Handler<T> handler) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		_HandlerEntry<T> entry = findByHandler(handler);
		if (entry == null) return false;
		_length--;
		if (_isDispatching) {
			_pendingCalls.add(new _PendingCall(_handlers.remove, [entry]));
		} else {
			_handlers.remove(entry);
		}
		return true;
	}

	bool contains(Handler<T> handler) {
		_HandlerEntry<T> entry = findByHandler(handler);
		return entry != null;
	}

	_HandlerEntry<T> findByHandler(Handler<T> handler) {
		_HandlerEntry<T> entry = _handlers.head;
		while (entry != null) {
			if (entry.handler == handler) return entry;
			entry = entry.next;
		}
		return null;
	}

	void clear() {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		_length = 0;
		if (_isDispatching) {
			_pendingCalls.add(new _PendingCall(_handlers.clear, []));
		} else {
			_handlers.clear();
		}
	}

	void dispatch(T arg) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		if (_isDispatching) throw new ConcurrentModificationError(this);
		_HandlerEntry<T> entry = _handlers.head;
		if (entry == null) return;

		_isDispatching = true;
		while (entry != null) {
			if (entry.isOnce) {
				_length--;
				_handlers.remove(entry);
			}
			entry.handler(arg);
			entry = entry.next;
		}

		// Handle any calls to the signal while we were in the middle of dispatching.
		if (_pendingCalls.head != null) {
			_PendingCall call = _pendingCalls.head;
			while (call != null) {
				call.invoke();
				call = call.next;
			}
			_pendingCalls.clear();
		}

		_isDispatching = false;
	}

	bool get isEmpty => _length == 0;

	bool get isNotEmpty => _length > 0;

	int get length => _length;

	void destroy() {
		clear();
		_enabled = false;
	}
}