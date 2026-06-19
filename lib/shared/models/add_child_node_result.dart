import '../enums/node_type.dart';

class AddChildNodeResult {
  final NodeType nodeType;
  final String name;

  const AddChildNodeResult({
    required this.nodeType,
    required this.name,
  });
}