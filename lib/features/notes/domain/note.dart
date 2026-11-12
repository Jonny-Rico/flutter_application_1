import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/features/notes/domain/note_checklist_item.dart';
import 'package:family_tasks/features/notes/domain/note_type.dart';

class Note {
  const Note({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.title,
    required this.body,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.sharedBy,
    this.sharedByName,
  });

  final String id;
  final String ownerId;
  final NoteType type;
  final String title;
  final String body;
  final List<NoteChecklistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sharedBy;
  final String? sharedByName;

  bool get isEmpty {
    if (title.trim().isNotEmpty) return false;
    if (type == NoteType.text) return body.trim().isEmpty;
    return items.every((item) => item.text.trim().isEmpty);
  }

  String get displayTitle {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty) return trimmed;
    if (type == NoteType.text) {
      for (final line in body.split('\n')) {
        if (line.trim().isNotEmpty) return line.trim();
      }
    } else {
      for (final item in items) {
        if (item.text.trim().isNotEmpty) return item.text.trim();
      }
    }
    return 'Untitled';
  }

  int get listOpenCount =>
      items.where((item) => !item.done && item.text.trim().isNotEmpty).length;

  Note copyWith({
    String? title,
    String? body,
    List<NoteChecklistItem>? items,
    DateTime? updatedAt,
    String? sharedBy,
    String? sharedByName,
  }) {
    return Note(
      id: id,
      ownerId: ownerId,
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sharedBy: sharedBy ?? this.sharedBy,
      sharedByName: sharedByName ?? this.sharedByName,
    );
  }

  Note copyForShare({
    required String id,
    required String ownerId,
    required String sharedBy,
    required String sharedByName,
    required DateTime now,
  }) {
    return Note(
      id: id,
      ownerId: ownerId,
      type: type,
      title: title,
      body: body,
      items: [for (final item in items) item],
      createdAt: now,
      updatedAt: now,
      sharedBy: sharedBy,
      sharedByName: sharedByName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'type': type.value,
      'title': title,
      'body': body,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sharedBy': sharedBy,
      'sharedByName': sharedByName,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'type': type.value,
      'title': title,
      'body': body,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'sharedBy': sharedBy,
      'sharedByName': sharedByName,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return Note(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String? ?? '',
      type: NoteType.fromValue(map['type'] as String?),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) =>
                    NoteChecklistItem.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
          : const [],
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      sharedBy: map['sharedBy'] as String?,
      sharedByName: map['sharedByName'] as String?,
    );
  }

  factory Note.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Note.fromMap({...data, 'id': doc.id});
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
