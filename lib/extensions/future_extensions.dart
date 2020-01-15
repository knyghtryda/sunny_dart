import 'dart:async';

import 'package:stream_transform/stream_transform.dart';

import '../helpers.dart';
import '../streams.dart';

extension FutureIterableExt<T> on Iterable<Future<T>> {
  Future<List<T>> waitAll({bool eagerError = true}) async {
    return await Future.wait(this.map((each) => Future.value(each)), eagerError: eagerError);
  }
}

extension FutureOrIterableExt<T> on Iterable<FutureOr<T>> {
  List<T> completed() {
    if (this == null) return [];
    return <T>[...this.whereType()];
  }

  Future<List<T>> awaitAll() {
    return Future.wait(this.map((v) => v.asFuture()));
  }
}

Future<Tuple<A, B>> awaitBoth<A, B>(FutureOr<A> a, FutureOr<B> b) async {
  return Tuple(await Future.value(a), await Future.value(b));
}

extension NestedFutureOr<T> on FutureOr<FutureOr<T>> {
  /// Unboxes a Future/FutureOr
  FutureOr<T> unbox() {
    final self = this;
    if (self is Future<T>) return self;
    if (self is Future<Future<T>>) return self.then((_) => _);
    if (self is Future<FutureOr<T>>) return self.then((_) async => await _);
    if (this is T) return this as T;
    return this as FutureOr<T>;
  }
}

extension FutureExt<T> on Future<T> {
  void ignore() {}

  FutureOr<Tuple<T, R>> to<R>(FutureOr<R> mapper(T input)) {
    final other = thenOr((T resolved) {
      return mapper(resolved).thenOr((second) {
        return Tuple<T, R>(resolved, second);
      });
    }).unbox();
    return other;
  }
}

extension ObjectTupleExt<X> on X {
  Tuple<X, Y> to<Y>(Y other) {
    return Tuple(this, other);
  }
}

extension FutureOrExts<T> on FutureOr<T> {
  ValueStream<T> toVStream() => this == null ? ValueStream.empty() : ValueStream.of(this);

  T resolve([T or]) =>
      resolveOrNull(or) ?? ((this is Future) ? illegalState<T>("Attempting to resolve a future.") : null);

  T resolveOrNull([T or]) => this is Future<T> ? (or == null) ? null : or : (this as T ?? or);

  FutureOr<R> thenCast<R>() => thenOr((self) => self as R);

  FutureOr<Tuple<T, R>> and<R>(FutureOr<R> mapper(T input)) {
    final other = thenOr((T resolved) {
      return mapper(resolved).thenOr((second) {
        return Tuple<T, R>(resolved, second);
      });
    }).unbox();
    return other;
  }

  Future<T> asFuture() => (this is Future) ? this as Future<T> : Future.value(this as T);

  FutureOr<R> thenOr<R>(R after(T resolved)) =>
      (this is Future<T>) ? asFuture().then(after) as FutureOr<R> : after(this as T) as FutureOr<R>;
}

extension StreamTxrExtensions<X> on Stream<X> {
  Stream<X> combine(Stream<X> other) {
    return orEmpty().merge(other);
  }

  Stream<X> orEmpty() {
    return this ?? Stream<X>.empty();
  }
}