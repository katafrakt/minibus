module minibus;

import std.stdio;
import std.variant;
import std.array;
import std.algorithm;
static import std.uuid;

alias Callback = void delegate(Variant);

class Minibus {
  class Subscription {
    string key;
    Callback callback;
    string id;

    this(string key, Callback callback) {
      this.key = key;
      this.callback = callback;
      this.id = std.uuid.randomUUID().toString();
    }
  }

	Subscription[] subscriptions;

	string subscribe(string key, Callback callback) {
		auto appender = appender(this.subscriptions);
		auto sub = new Subscription(key, callback);
		appender.put(sub);
		this.subscriptions = appender[];
		return sub.id;
	}

	void emit(string key, Variant *arg) {
		auto matching = this.subscriptions.filter!(sub => sub.key == key);
		foreach(Subscription sub; matching.array) {
			sub.callback(*arg);
		}
	}

  void emit(string key) {
    auto dummy_arg = new Variant();
    this.emit(key, dummy_arg);
  }

	void unsubscribe(string id) {
		this.subscriptions = this.subscriptions.filter!(sub => sub.id != id).array;
	}
}

// event without parameter
unittest {
  struct Counter {
    public int value;

    void increment() {
      this.value++;
    }
  }

  auto bus = new Minibus();
  auto counter = Counter(0);
  
  bus.subscribe("increment", (x) => counter.increment());
  assert(counter.value == 0);
  
  bus.emit("increment");
  assert(counter.value == 1);
  
  bus.emit("increment");
  assert(counter.value == 2);

  bus.emit("decrement");
  assert(counter.value == 2);
}

// event with a parameter
unittest {
  struct Counter {
    public int value;

    void increment(int by) {
      this.value += by;
    }

    void decrement(int by) {
      this.value -= by;
    }
  }

  auto bus = new Minibus();
  auto counter = Counter(0);
  auto counter2 = Counter(1);
  
  bus.subscribe("increment", (x) => counter.increment(x.get!(int)));
  bus.subscribe("increment", (x) => counter2.increment(x.get!(int)));
  bus.subscribe("decrement", (x) => counter.decrement(x.get!(int)));
  assert(counter.value == 0);
  
  bus.emit("increment", new Variant(5));
  assert(counter.value == 5);
  assert(counter2.value == 6);
  
  bus.emit("increment", new Variant(3));
  assert(counter.value == 8);
  assert(counter2.value == 9);

  bus.emit("decrement", new Variant(6));
  assert(counter.value == 2);
  assert(counter2.value == 9);
}

// unsubscribe
unittest {
  struct Counter {
    public int value;

    void increment() {
      this.value++;
    }
  }

  auto bus = new Minibus();
  auto counter = Counter(0);
  
  auto sub_id = bus.subscribe("increment", (x) => counter.increment());
  assert(counter.value == 0);
  
  bus.emit("increment");
  assert(counter.value == 1);

  bus.unsubscribe(sub_id);
  
  bus.emit("increment");
  assert(counter.value == 1);
}

// unsubscribe non-existing subscription
unittest {
  import std.exception : assertNotThrown;
  
  auto bus = new Minibus();
  assertNotThrown(bus.unsubscribe("abc"));
}