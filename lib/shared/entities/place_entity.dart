import 'package:objectbox/objectbox.dart';

@Entity()
class PlaceEntity {
  @Id()
  int id = 0;

  String uuid;

  String name;

  String type;

  String? description;

  bool isArchived;

  DateTime createdAt;

  DateTime updatedAt;

  int sortOrder;

  PlaceEntity({
    required this.uuid,
    required this.name,
    required this.type,
    this.description,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
  });
}