class AppModelField {
  const AppModelField({
    required this.name,
    required this.type,
    this.initValue,
    this.initListValue,
    this.initMapValue,
    this.serializeField,
  });

  final String name;
  final String type;
  final Object? initValue;
  final List<Object>? initListValue;
  final Map<Object, Object>? initMapValue;
  final bool? serializeField;

  @override
  String toString() {
    if (initValue != null) {
      return '$type $name = $initValue';
    }

    if (initListValue != null) {
      return '$type $name = $initListValue';
    }

    if (initMapValue != null) {
      return '$type $name = $initMapValue';
    }

    return 'Unexpected AppModelField instance';
  }
}
