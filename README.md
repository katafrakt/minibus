# Minibus

A minimalistic, sychronous event bus for D language. Inspired by [nanobus](https://github.com/choojs/nanobus) for JavaScript.

## Usage

```d
import std.variant;

import minibus;

struct Counter {
    public int value;

    void increment(int by = 1) {
        this.value += by;
    }
}

void main(string[] args) {
    auto bus = new Minibus();
    auto counter = Counter(0);

    string sub_id = bus.subscribe("increment", (Variant x) => counter.increment()); // Explicit type for callback

    bus.emit("increment");
    // counter.value is now 1
    assert(counter.value == 1); // Added for verification

    bus.emit("decrement");
    // nothing is subscribed to this event, so the value remains unchanged
    assert(counter.value == 1); // Added for verification

    bus.unsubscribe(sub_id);
    bus.emit("increment");
    // counter is unsubscribed from "increment" event, so the value remains unchanged
    assert(counter.value == 1); // Added for verification

    bus.subscribe("increment", (Variant value) => counter.increment(value.get!int)); // Explicit type, fixed syntax
    bus.emit("increment", Variant(10)); // Simplified Variant creation, no 'new'
    // counter.value is now 11
    assert(counter.value == 11); // Added for verification
}
```
