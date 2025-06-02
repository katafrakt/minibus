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

    private Subscription[] subscriptions;

    string subscribe(string key, Callback callback) {
        auto sub = new Subscription(key, callback);
        subscriptions ~= sub; // Simplified append, safer and idiomatic
        return sub.id;
    }

    void emit(string key, Variant arg) { // Changed to pass Variant directly, not pointer
        auto matching = subscriptions.filter!(sub => sub.key == key);
        foreach (sub; matching) { // No need for .array, foreach works directly
            sub.callback(arg);
        }
    }

    void emit(string key) {
        Variant dummy = Variant(); // Simplified dummy creation, no pointer
        this.emit(key, dummy);
    }

    void unsubscribe(string id) {
        subscriptions = subscriptions.filter!(sub => sub.id != id).array;
    }
}

// Event without parameter
unittest {
    struct Counter {
        public int value;

        void increment() {
            this.value++;
        }
    }

    auto bus = new Minibus();
    auto counter = Counter(0);
    
    bus.subscribe("increment", (Variant x) => counter.increment()); // Explicit Variant type
    assert(counter.value == 0);
    
    bus.emit("increment");
    assert(counter.value == 1);
    
    bus.emit("increment");
    assert(counter.value == 2);

    bus.emit("decrement");
    assert(counter.value == 2);
}

// Event with a parameter
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
    
    bus.subscribe("increment", (Variant x) => counter.increment(x.get!int));
    bus.subscribe("increment", (Variant x) => counter2.increment(x.get!int));
    bus.subscribe("decrement", (Variant x) => counter.decrement(x.get!int));
    assert(counter.value == 0);
    
    bus.emit("increment", Variant(5)); // Simplified Variant creation
    assert(counter.value == 5);
    assert(counter2.value == 6);
    
    bus.emit("increment", Variant(3));
    assert(counter.value == 8);
    assert(counter2.value == 9);

    bus.emit("decrement", Variant(6));
    assert(counter.value == 2);
    assert(counter2.value == 9);
}

// Unsubscribe
unittest {
    struct Counter {
        public int value;

        void increment() {
            this.value++;
        }
    }

    auto bus = new Minibus();
    auto counter = Counter(0);
    
    auto sub_id = bus.subscribe("increment", (Variant x) => counter.increment());
    assert(counter.value == 0);
    
    bus.emit("increment");
    assert(counter.value == 1);

    bus.unsubscribe(sub_id);
    
    bus.emit("increment");
    assert(counter.value == 1);
}

// Unsubscribe non-existing subscription
unittest {
    import std.exception : assertNotThrown;
    
    auto bus = new Minibus();
    assertNotThrown!Error(bus.unsubscribe("abc")); // Specify Error for clarity
}
