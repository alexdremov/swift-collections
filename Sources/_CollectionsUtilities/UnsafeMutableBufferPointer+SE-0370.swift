//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// Note: These are adapted from SE-0370 in the Swift 5.8 Standard Library.

extension UnsafeMutableBufferPointer {
  /// Deinitializes every instance in this buffer.
  ///
  /// The region of memory underlying this buffer must be fully initialized.
  /// After calling `deinitialize(count:)`, the memory is uninitialized,
  /// but still bound to the `Element` type.
  ///
  /// - Note: All buffer elements must already be initialized.
  ///
  /// - Returns: A raw buffer to the same range of memory as this buffer.
  ///   The range of memory is still bound to `Element`.
  @discardableResult
  @inlinable
  public func deinitialize() -> UnsafeMutableRawBufferPointer {
    guard let start = baseAddress else { return .init(start: nil, count: 0) }
    start.deinitialize(count: count)
    return .init(start: UnsafeMutableRawPointer(start),
                 count: count * MemoryLayout<Element>.stride)
  }
}

extension UnsafeMutableBufferPointer {
  /// Initializes the buffer's memory with
  /// every element of the source.
  ///
  /// Prior to calling the `initialize(fromContentsOf:)` method on a buffer,
  /// the memory referenced by the buffer must be uninitialized,
  /// or the `Element` type must be a trivial type. After the call,
  /// the memory referenced by the buffer up to, but not including,
  /// the returned index is initialized.
  /// The buffer must reference enough memory to accommodate
  /// `source.count` elements.
  ///
  /// The returned index is the position of the next uninitialized element
  /// in the buffer, one past the index of the last element written.
  /// If `source` contains no elements, the returned index is equal to the
  /// buffer's `startIndex`. If `source` contains as many elements as the buffer
  /// can hold, the returned index is equal to the buffer's `endIndex`.
  ///
  /// - Precondition: `self.count` >= `source.count`
  ///
  /// - Note: The memory regions referenced by `source` and this buffer
  ///     must not overlap.
  ///
  /// - Parameter source: A collection of elements to be used to
  ///     initialize the buffer's storage.
  /// - Returns: The index one past the last element of the buffer initialized
  ///     by this function.
  @inlinable
  public func initialize<C: Collection>(
    fromContentsOf source: C
  ) -> Index
  where C.Element == Element {
    let count: Int? = source._withContiguousStorageIfAvailable_SR14663 {
      guard let sourceAddress = $0.baseAddress, !$0.isEmpty else {
        return 0
      }
      precondition(
        $0.count <= self.count,
        "buffer cannot contain every element from source."
      )
      baseAddress?.initialize(from: sourceAddress, count: $0.count)
      return $0.count
    }
    if let count = count {
      return startIndex.advanced(by: count)
    }

    var (iterator, copied) = source._copyContents(initializing: self)
    precondition(
      iterator.next() == nil,
      "buffer cannot contain every element from source."
    )
    return startIndex.advanced(by: copied)
  }

  /// Moves every element of an initialized source buffer into the
  /// uninitialized memory referenced by this buffer, leaving the source memory
  /// uninitialized and this buffer's memory initialized.
  ///
  /// Prior to calling the `moveInitialize(fromContentsOf:)` method on a buffer,
  /// the memory it references must be uninitialized,
  /// or its `Element` type must be a trivial type. After the call,
  /// the memory referenced by the buffer up to, but not including,
  /// the returned index is initialized. The memory referenced by
  /// `source` is uninitialized after the function returns.
  /// The buffer must reference enough memory to accommodate
  /// `source.count` elements.
  ///
  /// The returned index is the position of the next uninitialized element
  /// in the buffer, one past the index of the last element written.
  /// If `source` contains no elements, the returned index is equal to the
  /// buffer's `startIndex`. If `source` contains as many elements as the buffer
  /// can hold, the returned index is equal to the buffer's `endIndex`.
  ///
  /// - Precondition: `self.count` >= `source.count`
  ///
  /// - Note: The memory regions referenced by `source` and this buffer
  ///     may overlap.
  ///
  /// - Parameter source: A buffer containing the values to copy. The memory
  ///     region underlying `source` must be initialized.
  /// - Returns: The index one past the last element of the buffer initialized
  ///     by this function.
  @inlinable
  @_alwaysEmitIntoClient
  public func moveInitialize(fromContentsOf source: Self) -> Index {
    guard let sourceAddress = source.baseAddress, !source.isEmpty else {
      return startIndex
    }
    precondition(
      source.count <= self.count,
      "buffer cannot contain every element from source."
    )
    baseAddress?.moveInitialize(from: sourceAddress, count: source.count)
    return startIndex.advanced(by: source.count)
  }

  /// Moves every element of an initialized source buffer into the
  /// uninitialized memory referenced by this buffer, leaving the source memory
  /// uninitialized and this buffer's memory initialized.
  ///
  /// Prior to calling the `moveInitialize(fromContentsOf:)` method on a buffer,
  /// the memory it references must be uninitialized,
  /// or its `Element` type must be a trivial type. After the call,
  /// the memory referenced by the buffer up to, but not including,
  /// the returned index is initialized. The memory referenced by
  /// `source` is uninitialized after the function returns.
  /// The buffer must reference enough memory to accommodate
  /// `source.count` elements.
  ///
  /// The returned index is the position of the next uninitialized element
  /// in the buffer, one past the index of the last element written.
  /// If `source` contains no elements, the returned index is equal to the
  /// buffer's `startIndex`. If `source` contains as many elements as the buffer
  /// can hold, the returned index is equal to the buffer's `endIndex`.
  ///
  /// - Precondition: `self.count` >= `source.count`
  ///
  /// - Note: The memory regions referenced by `source` and this buffer
  ///     may overlap.
  ///
  /// - Parameter source: A buffer containing the values to copy. The memory
  ///     region underlying `source` must be initialized.
  /// - Returns: The index one past the last element of the buffer initialized
  ///     by this function.
  @inlinable
  @_alwaysEmitIntoClient
  public func moveInitialize(fromContentsOf source: Slice<Self>) -> Index {
    return moveInitialize(fromContentsOf: Self(rebasing: source))
  }

  /// Initializes the element at `index` to the given value.
  ///
  /// The memory underlying the destination element must be uninitialized,
  /// or `Element` must be a trivial type. After a call to `initialize(to:)`,
  /// the memory underlying this element of the buffer is initialized.
  ///
  /// - Parameters:
  ///   - value: The value used to initialize the buffer element's memory.
  ///   - index: The index of the element to initialize
  @inlinable
  @_alwaysEmitIntoClient
  public func initializeElement(at index: Index, to value: Element) {
    assert(startIndex <= index && index < endIndex)
    let p = baseAddress.unsafelyUnwrapped.advanced(by: index)
    p.initialize(to: value)
  }

  /// Retrieves and returns the element at `index`,
  /// leaving that element's underlying memory uninitialized.
  ///
  /// The memory underlying the element at `index` must be initialized.
  /// After calling `moveElement(from:)`, the memory underlying this element
  /// of the buffer is uninitialized, and still bound to type `Element`.
  ///
  /// - Parameters:
  ///   - index: The index of the buffer element to retrieve and deinitialize.
  /// - Returns: The instance referenced by this index in this buffer.
  @inlinable
  @_alwaysEmitIntoClient
  public func moveElement(from index: Index) -> Element {
    assert(startIndex <= index && index < endIndex)
    return baseAddress.unsafelyUnwrapped.advanced(by: index).move()
  }

  /// Deinitializes the memory underlying the element at `index`.
  ///
  /// The memory underlying the element at `index` must be initialized.
  /// After calling `deinitializeElement()`, the memory underlying this element
  /// of the buffer is uninitialized, and still bound to type `Element`.
  ///
  /// - Parameters:
  ///   - index: The index of the buffer element to deinitialize.
  @inlinable
  @_alwaysEmitIntoClient
  public func deinitializeElement(at index: Index) {
    assert(startIndex <= index && index < endIndex)
    let p = baseAddress.unsafelyUnwrapped.advanced(by: index)
    p.deinitialize(count: 1)
  }
}

extension Slice {
  /// Initializes the buffer slice's memory with with
  /// every element of the source.
  ///
  /// Prior to calling the `initialize(fromContentsOf:)` method
  /// on a buffer slice, the memory it references must be uninitialized,
  /// or the `Element` type must be a trivial type. After the call,
  /// the memory referenced by the buffer slice up to, but not including,
  /// the returned index is initialized.
  /// The buffer slice must reference enough memory to accommodate
  /// `source.count` elements.
  ///
  /// The returned index is the index of the next uninitialized element
  /// in the buffer slice, one past the index of the last element written.
  /// If `source` contains no elements, the returned index is equal to
  /// the buffer slice's `startIndex`. If `source` contains as many elements
  /// as the buffer slice can hold, the returned index is equal to
  /// to the slice's `endIndex`.
  ///
  /// - Precondition: `self.count` >= `source.count`
  ///
  /// - Note: The memory regions referenced by `source` and this buffer slice
  ///     must not overlap.
  ///
  /// - Parameter source: A collection of elements to be used to
  ///     initialize the buffer slice's storage.
  /// - Returns: The index one past the last element of the buffer slice
  ///    initialized by this function.
  @inlinable
  @_alwaysEmitIntoClient
  public func initialize<C: Collection>(
    fromContentsOf source: C
  ) -> Index where Base == UnsafeMutableBufferPointer<C.Element> {
    let buffer = Base(rebasing: self)
    let index = buffer.initialize(fromContentsOf: source)
    let distance = buffer.distance(from: buffer.startIndex, to: index)
    return startIndex.advanced(by: distance)
  }

  /// Moves every element of an initialized source buffer into the
  /// uninitialized memory referenced by this buffer slice, leaving the
  /// source memory uninitialized and this buffer slice's memory initialized.
  ///
  /// Prior to calling the `moveInitialize(fromContentsOf:)` method on a
  /// buffer slice, the memory it references must be uninitialized,
  /// or its `Element` type must be a trivial type. After the call,
  /// the memory referenced by the buffer slice up to, but not including,
  /// the returned index is initialized. The memory referenced by
  /// `source` is uninitialized after the function returns.
  /// The buffer slice must reference enough memory to accommodate
  /// `source.count` elements.
  ///
  /// The returned index is the position of the next uninitialized element
  /// in the buffer slice, one past the index of the last element written.
  /// If `source` contains no elements, the returned index is equal to the
  /// slice's `startIndex`. If `source` contains as many elements as the slice
  /// can hold, the returned index is equal to the slice's `endIndex`.
  ///
  /// - Note: The memory regions referenced by `source` and this buffer slice
  ///     may overlap.
  ///
  /// - Precondition: `self.count` >= `source.count`
  ///
  /// - Parameter source: A buffer containing the values to copy.
  ///     The memory region underlying `source` must be initialized.
  /// - Returns: The index one past the last element of the buffer slice
  ///    initialized by this function.
  @inlinable
  @_alwaysEmitIntoClient
  public func moveInitialize<Element>(
    fromContentsOf source: UnsafeMutableBufferPointer<Element>
  ) -> Index where Base == UnsafeMutableBufferPointer<Element> {
    let buffer = Base(rebasing: self)
    let index = buffer.moveInitialize(fromContentsOf: source)
    let distance = buffer.distance(from: buffer.startIndex, to: index)
    return startIndex.advanced(by: distance)
  }

  /// Moves every element of an initialized source buffer slice into the
  /// uninitialized memory referenced by this buffer slice, leaving the
  /// source memory uninitialized and this buffer slice's memory initialized.
  ///
  /// Prior to calling the `moveInitialize(fromContentsOf:)` method on a
  /// buffer slice, the memory it references must be uninitialized,
  /// or its `Element` type must be a trivial type. After the call,
  /// the memory referenced by the buffer slice up to, but not including,
  /// the returned index is initialized. The memory referenced by
  /// `source` is uninitialized after the function returns.
  /// The buffer slice must reference enough memory to accommodate
  /// `source.count` elements.
  ///
  /// The returned index is the position of the next uninitialized element
  /// in the buffer slice, one past the index of the last element written.
  /// If `source` contains no elements, the returned index is equal to the
  /// slice's `startIndex`. If `source` contains as many elements as the slice
  /// can hold, the returned index is equal to the slice's `endIndex`.
  ///
  /// - Note: The memory regions referenced by `source` and this buffer slice
  ///     may overlap.
  ///
  /// - Precondition: `self.count` >= `source.count`
  ///
  /// - Parameter source: A buffer slice containing the values to copy.
  ///     The memory region underlying `source` must be initialized.
  /// - Returns: The index one past the last element of the buffer slice
  ///    initialized by this function.
  @inlinable
  @_alwaysEmitIntoClient
  public func moveInitialize<Element>(
    fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>
  ) -> Index where Base == UnsafeMutableBufferPointer<Element> {
    let buffer = Base(rebasing: self)
    let index = buffer.moveInitialize(fromContentsOf: source)
    let distance = buffer.distance(from: buffer.startIndex, to: index)
    return startIndex.advanced(by: distance)
  }

  /// Deinitializes every instance in this buffer slice.
  ///
  /// The region of memory underlying this buffer slice must be fully
  /// initialized. After calling `deinitialize(count:)`, the memory
  /// is uninitialized, but still bound to the `Element` type.
  ///
  /// - Note: All buffer elements must already be initialized.
  ///
  /// - Returns: A raw buffer to the same range of memory as this buffer.
  ///   The range of memory is still bound to `Element`.
  @discardableResult
  @inlinable
  @_alwaysEmitIntoClient
  public func deinitialize<Element>() -> UnsafeMutableRawBufferPointer
  where Base == UnsafeMutableBufferPointer<Element> {
    Base(rebasing: self).deinitialize()
  }

  /// Initializes the element at `index` to the given value.
  ///
  /// The memory underlying the destination element must be uninitialized,
  /// or `Element` must be a trivial type. After a call to `initialize(to:)`,
  /// the memory underlying this element of the buffer slice is initialized.
  ///
  /// - Parameters:
  ///   - value: The value used to initialize the buffer element's memory.
  ///   - index: The index of the element to initialize
  @inlinable
  @_alwaysEmitIntoClient
  public func initializeElement<Element>(at index: Int, to value: Element)
  where Base == UnsafeMutableBufferPointer<Element> {
    assert(startIndex <= index && index < endIndex)
    base.baseAddress.unsafelyUnwrapped.advanced(by: index).initialize(to: value)
  }
}

#if swift(<5.8)
extension UnsafeMutableBufferPointer {
  /// Updates every element of this buffer's initialized memory.
  ///
  /// The buffer’s memory must be initialized or its `Element` type
  /// must be a trivial type.
  ///
  /// - Note: All buffer elements must already be initialized.
  ///
  /// - Parameters:
  ///   - repeatedValue: The value used when updating this pointer's memory.
  @_alwaysEmitIntoClient
  public func update(repeating repeatedValue: Element) {
    guard let dstBase = baseAddress else { return }
    dstBase.update(repeating: repeatedValue, count: count)
  }
}
#endif

#if swift(<5.8)
extension Slice {
  /// Updates every element of this buffer slice's initialized memory.
  ///
  /// The buffer slice’s memory must be initialized or its `Element`
  /// must be a trivial type.
  ///
  /// - Note: All buffer elements must already be initialized.
  ///
  /// - Parameters:
  ///   - repeatedValue: The value used when updating this pointer's memory.
  @_alwaysEmitIntoClient
  public func update<Element>(repeating repeatedValue: Element)
  where Base == UnsafeMutableBufferPointer<Element> {
    Base(rebasing: self).update(repeating: repeatedValue)
  }
}
#endif
