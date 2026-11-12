enum NoteType {
  text('text'),
  list('list');

  const NoteType(this.value);

  final String value;

  static NoteType fromValue(String? value) {
    return NoteType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NoteType.text,
    );
  }
}
