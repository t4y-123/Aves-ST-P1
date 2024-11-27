import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class ScenarioByFixDetails extends Equatable {
  final String name;
  final bool autoTypeSuffix;
  final ScenarioLoadType loadType;

  @override
  List<Object?> get props => [name, autoTypeSuffix, loadType];

  const ScenarioByFixDetails({
    required this.name,
    required this.autoTypeSuffix,
    required this.loadType,
  });

  ScenarioByFixDetails copyWith({
    String? name,
  }) {
    return ScenarioByFixDetails(
      name: name ?? this.name,
      autoTypeSuffix: autoTypeSuffix,
      loadType: loadType,
    );
  }

  factory ScenarioByFixDetails.fromMap(Map map) {
    return ScenarioByFixDetails(
      name: map['name'] as String,
      autoTypeSuffix: (map['autoLock'] as int? ?? 0) != 0,
      loadType: ScenarioLoadType.values.safeByName(map['loadType'] as String, ScenarioLoadType.excludeUnique),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'autoLock': autoTypeSuffix ? 1 : 0,
        'loadType': loadType.name,
      };
}
