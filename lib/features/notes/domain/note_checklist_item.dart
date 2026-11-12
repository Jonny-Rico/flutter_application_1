class NoteChecklistItem {
  const NoteChecklistItem({
    required this.id,
    required this.text,
    required this.done,
  });

  final String id;
  final String text;
  final bool done;

  NoteChecklistItem copyWith({String? text, bool? done}) {
    return NoteChecklistItem(
      id: id,
      text: text ?? this.text,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text, 'done': done};
  }

  factory NoteChecklistItem.fromMap(Map<String, dynamic> map) {
    return NoteChecklistItem(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      done: map['done'] as bool? ?? false,
    );
  }
}
