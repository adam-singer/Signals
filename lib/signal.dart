part of signals;

class _HandlerEntry {

	_Handler handler;
	bool isOnce;

	_HandlerEntry([this.handler, this.isOnce]);

	int get hashCode => handler.hashCode;

	bool operator ==(_HandlerEntry other) {
		return other.handler == this.handler;
	}

}

typedef _Handler(T);

class Signal<T> {

	bool _enabled = true;
	bool _isDispatching = false;

	List<_Handler> _handlers = new List<_Handler>();
	List<_Handler> _pendingHandlers = new List<_Handler>();

	Signal() {
	}

	bool add(_Handler handler, [bool isOnce = false]) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		if (_isDispatching) {
			_pendingHandlers.add(handler);
		} else {
			_handlers.add(handler);
		}
		return true;
	}

	bool remove(_Handler handler) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		if (_isDispatching) _pendingHandlers.remove(handler);
		return _handlers.remove(handler);
	}

	void removeAll() {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		_handlers.clear();
		_pendingHandlers.clear();
	}

	void dispatch(T args) {
		if (!_enabled) throw new StateError("This Signal has been destroyed.");
		if (_isDispatching) throw new ConcurrentModificationError(this);
		_isDispatching = true;
		_handlers.forEach((_Handler element) {
			element(args);
		});
		if (_pendingHandlers.length > 0) _handlers.addAll(_pendingHandlers);
		_pendingHandlers.clear();
		_isDispatching = false;
	}

	void destroy() {
		removeAll();
		_enabled = false;
	}

}

