import 'package:objectbox/objectbox.dart';

@Entity()
class RoomEntity {
  @Id()
  int id = 0;

  String uuid;

  String placeUuid;

  String name;

  String? description;

  bool isArchived;

  DateTime createdAt;

  DateTime updatedAt;

  int sortOrder;

  RoomEntity({
    required this.uuid,
    required this.placeUuid,
    required this.name,
    this.description,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
  });
}