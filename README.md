[![Build Status](https://drone.io/github.com/nbilyk/Signals/status.png)](https://drone.io/github.com/nbilyk/Signals/latest)

Signals for Dart
=======

 Signals are a light-weight, strongly-typed way to implement the observer pattern. They allow you
 to explicitly define the messages your objects provide, without relying on metadata or documentation.

 The Signal object at a basic level is a list of methods to be invoked when the Signal is dispatched.

 Usage Example:

     import 'package:blix_signals/signals.dart';

     class MilkEvent {
     	num amount;
     	num duration;
     	MilkEvent(this.amount, this.duration);
     }

     abstract class IMilkable {
     	ISignal<MilkEvent> get milked;
     }

     class Cow implements IMilkable {
     	Signal<MilkEvent> _milked = new Signal<MilkEvent>();

     	ISignal<MilkEvent> get milked => _milked;

     	void milk() {
     		if (_milked.isNotEmpty) {
     			_milked.dispatch(new MilkEvent(1, 1));
     		}
     	}
     }

     class DeliveryPerson {
     	void watchMilkable(IMilkable milkable) {
     		milkable.milked.add((MilkEvent e) => fillBottle(e.amount));
     	}

     	void fillBottle(int amount) {
     		print("Added ${amount} milk");
     	}
     }

     void main() {
     	var cow = new Cow();
     	var deliveryPerson = new DeliveryPerson();
     	deliveryPerson.watchMilkable(cow);
     	cow.milk(); // added 1 milk
     }

 Three conventions should be pointed out:

 1. The signal is described in past tense.

 2. The dispatch is surrounded by an [isNotEmpty] check.  This is only important for performance if the message
 requires work to be done.  That is, if the message requires a new object to be created, it is best to
 optimize for the case if there are no handlers.

 3. The exposed interface is using ISignal instead of Signal. The ISignal interface does not expose the
 dispatch(T) function. This is because it's generally a bad practice to broadcast a message on behalf of
 another object.