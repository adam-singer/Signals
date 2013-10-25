part of signals;

typedef num ComputeDistance<E>(E p1, E p2);
class Space<PointType> {
  final ComputeDistance<PointType> distance;
  Space(this.distance);
}

/**
 * An type definition for a callback.
 */
typedef _Handler<F>(F param);

class _HandlerEntry<E> extends LinkedListEntry {

	final _Handler<E> handler;
	final bool isOnce;

	_HandlerEntry(this.handler, this.isOnce);
}



class Signal<T> {

	bool _enabled = true;
	bool _isDispatching = false;

	final LinkedList<_HandlerEntry<T>> _handlers = new LinkedList<_HandlerEntry<T>>();
	final LinkedList<_HandlerEntry<T>> _pendingHandlers = new LinkedList<_HandlerEntry<T>>();
	final Map<_Handler<T>, _HandlerEntry<T>> _handlerEntryMap = new Map<_Handler<T>, _HandlerEntry<T>>();

	Signal() {
	}

	bool add(_Handler<T> handler, [bool isOnce = false]) {
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

	bool addOnce(_Handler<T> handler) {
		add(handler, true);
	}

	bool remove(_Handler<T> handler) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		if (!_handlerEntryMap.containsKey(handler)) return false;
		_HandlerEntry<T> entry = _handlerEntryMap.remove(handler);
		if (_isDispatching) _pendingHandlers.remove(entry);
		bool success = _handlers.remove(entry);
		return true;
	}

	void removeAll() {
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
			if (_pendingHandlers.length > 0) _handlers.addAll(_pendingHandlers);
			_pendingHandlers.clear();
		}
		_isDispatching = false;
	}

	void destroy() {
		removeAll();
		_enabled = false;
	}
}

