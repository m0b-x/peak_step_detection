/// A minimal, dependency‑free fixed‑size circular buffer.
/// Keeps the *capacity* most‑recent elements.
///
///  • `add`      – O(1) append (overwrites oldest when full)
///  • indexing   – O(1) random read in logical order
///  • `toList()` – O(n) copy in logical order (oldest → newest)
class CircularBuffer<T> extends Iterable<T> {
  CircularBuffer(this.capacity)
      : assert(capacity > 0),
        _buf = List.filled(capacity, null, growable: false);

  final int capacity;
  final List<T?> _buf;
  int _head = 0;
  int _len = 0;

  @override
  int get length => _len;

  T operator [](int i) {
    if (i < 0 || i >= _len) {
      throw RangeError.index(i, this, 'index', null, _len);
    }
    return _buf[(_head + i) % capacity] as T;
  }

  /// Adds a value, overwriting the oldest when full.
  void add(T v) {
    final next = (_head + _len) % capacity;
    _buf[next] = v;
    if (_len < capacity) {
      _len++;
    } else {
      // buffer full – logical window slides forward
      _head = (_head + 1) % capacity;
    }
  }

  /// Clears the buffer (but keeps allocated memory).
  void clear() {
    _head = 0;
    _len = 0;
  }

  @override
  Iterator<T> get iterator => _CircularBufferIterator<T>(this);

  @override
  List<T> toList({bool growable = true}) =>
      List<T>.generate(_len, (i) => this[i], growable: growable);
}

class _CircularBufferIterator<T> implements Iterator<T> {
  _CircularBufferIterator(this._buf);
  final CircularBuffer<T> _buf;
  int _index = -1;

  @override
  T get current => _buf[_index];

  @override
  bool moveNext() {
    if (_index + 1 >= _buf._len) return false;
    _index++;
    return true;
  }
}
