/// The stable identity of an action across layout passes.
extension type ActionId._(String value) {
  /// Creates an action identifier from [value].
  ///
  /// The value must not be empty and must not contain leading or trailing
  /// whitespace.
  ActionId(String value) : this._(_validateIdValue(value, 'value'));
}

/// The stable identity of root-level placement constraints.
extension type ActionPlacementConstraintId._(String value) {
  /// Creates a placement-constraint identifier from [value].
  ///
  /// The value must not be empty and must not contain leading or trailing
  /// whitespace.
  ActionPlacementConstraintId(String value)
    : this._(_validateIdValue(value, 'value'));
}

/// A renderer-owned key for one primary-region widget layout.
extension type ActionLayoutOptionId._(String value) {
  /// Creates a layout option identifier from [value].
  ///
  /// The value is scoped to one `ActionLayoutProfile` and has no visual meaning
  /// to core resolution. A renderer commonly uses values such as `toolbar` or
  /// `icon`, but Core treats both as opaque keys.
  ActionLayoutOptionId(String value) : this._(_validateIdValue(value, 'value'));
}

String _validateIdValue(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(
      value,
      name,
      'must not be empty or contain leading or trailing whitespace',
    );
  }
  return value;
}
