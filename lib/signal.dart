// Copyright (c) 2013, Nicholas BIlyk.
// All rights reserved. Use of this source code is governed by an
// Apache 2.0 license that can be found in the LICENSE file.

part of signals;

/**
 * A type definition for a callback.
 */
typedef Handler<T>(T param);

/**
 * A private class used for handler entries in the Signal's linked lists.
 */
class _HandlerEntry<T> extends LinkedListEntry {

	final Handler<T> handler;
	final bool isOnce;

	_HandlerEntry(this.handler, this.isOnce);
}

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
	 *
	 * Special case:
	 * If a handler is added with isOnce = true, and the same handler is added again with isOnce = false, the second
	 * add will be ignored. Handlers are tracked only by the method, and not by the isOnce flag.
	 * If you are intending to change a once handler to a repeated handler or visa versa, first remove the handler,
	 * then re-add.
	 *
	*/
	bool add(Handler<T> handler, [bool isOnce = false]);

	/**
	 * A convenience method which calls add() with the addOnce parameter set to true.
	 * @see #add
	 */
	bool addOnce(Handler<T> handler);

	/**
	 * Removes the given handler from the list.
	 *
	 * This call is not blocked during a dispatch.
	 */
	bool remove(Handler<T> handler);

	/**
	 * Removes all handlers from the list.
	 */
	void clear();

	/**
	 * Dispatches the Signal, invoking every added handler.
	 */
	void dispatch(T arg);

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

/**
 * Signals are similar to Events, they are designed to
 */
class Signal<T> implements ISignal {

	bool _enabled = true;
	bool _isDispatching = false;

	final LinkedList<_HandlerEntry<T>> _handlers = new LinkedList<_HandlerEntry<T>>();
	final LinkedList<_HandlerEntry<T>> _pendingHandlers = new LinkedList<_HandlerEntry<T>>();
	final Map<Handler<T>, _HandlerEntry<T>> _handlerEntryMap = new Map<Handler<T>, _HandlerEntry<T>>();

	/**
	 * Creates a new Signal object.
	 */
	Signal() {
	}

	bool add(Handler<T> handler, [bool isOnce = false]) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		if (_handlerEntryMap.containsKey(handler)) return false;
		_HandlerEntry<T> entry = new _HandlerEntry<T>(handler, isOnce);
		_handlerEntryMap[handler] = entry;

		if (_isDispatching) {
			_pendingHandlers.add(entry);
		} else {
			_handlers.add(entry);
		}
		return true;
	}

	bool addOnce(Handler<T> handler) {
		add(handler, true);
	}

	bool remove(Handler<T> handler) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		if (!_handlerEntryMap.containsKey(handler)) return false;
		_HandlerEntry<T> entry = _handlerEntryMap.remove(handler);
		if (_isDispatching) _pendingHandlers.remove(entry);
		bool success = _handlers.remove(entry);
		return true;
	}

	void clear() {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		_handlers.clear();
		_pendingHandlers.clear();
		_handlerEntryMap.clear();
	}

	void dispatch(T arg) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		if (_isDispatching) throw new ConcurrentModificationError(this);
		_isDispatching = true;
		if (_handlers.isNotEmpty) {
			_HandlerEntry<T> current = _handlers.first;
			while (current != null) {
				_HandlerEntry<T> next = current.next;
				current.handler(arg);
				if (current.isOnce) {
					_handlers.remove(current);
				}
	      current = next;
	    }
			if (_pendingHandlers.length > 0) {
				_handlers.addAll(_pendingHandlers);
				_pendingHandlers.clear();
			}
		}
		_isDispatching = false;
	}

	bool get isEmpty => _handlers.isEmpty && _pendingHandlers.isEmpty;

	bool get isNotEmpty => !isEmpty;

	void destroy() {
		clear();
		_enabled = false;
	}
}

