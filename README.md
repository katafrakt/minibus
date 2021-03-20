# Minibus

A minimalistic, sychronous event bus for D language. Inspired by [nanobus](https://github.com/choojs/nanobus) for JavaScript.

## Usage

```d
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

  string sub_id = bus.subscribe("increment", (x) => counter.increment());

  bus.emit("increment");
  // counter.value is now 1

  bus.emit("decrement");
  // nothing is subscribed to this event, so the value remains unchanged

  bus.unsubscribe(sub_id);
  bus.emit("increment");
  // counter is unsubscribed from "increment" event, so the value remains unchanged

  bus.subscribe("increment", (value) => counter.increment(value.get!int()));
  bus.emit("increment", new Variant(10));
  // counter.value is now 11
}
```