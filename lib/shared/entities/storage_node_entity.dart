import 'package:objectbox/objectbox.dart';

@Entity()
class StorageNodeEntity {
  @Id()
  int id = 0;

  String uuid;

  String roomUuid;

  String? parentUuid;

  String nodeType;

  String name;

  String? description;

  String? photoPath;

  String? tags;

  bool isImportant;

  bool isArchived;

  String syncStatus;

  DateTime createdAt;

  DateTime updatedAt;

  @Property(type: PropertyType.date)
  DateTime? viewedAt;

  int sortOrder;

  @Property(type: PropertyType.date)
  DateTime? expiryDate;

  bool trackExpiry;

  StorageNodeEntity({
    required this.uuid,
    required this.roomUuid,
    this.parentUuid,
    required this.nodeType,
    required this.name,
    this.description,
    this.photoPath,
    this.tags,
    this.isImportant = false,
    this.isArchived = false,
    this.syncStatus = 'localOnly',
    required this.createdAt,
    required this.updatedAt,
    this.viewedAt,
    this.sortOrder = 0,
    this.expiryDate,
    this.trackExpiry = false,
  });
}
