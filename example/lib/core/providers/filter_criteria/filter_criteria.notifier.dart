import 'package:filterable_annotation/filter_criteria.dart';
import 'package:filterable_annotation/sort_criteria.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filter_criteria.notifier.g.dart';

@Riverpod(keepAlive: true)
class FilterCriteriaNotifier extends _$FilterCriteriaNotifier {
  @override
  FilterState build() {
    return FilterState();
  }

  void updateFilters(FilterState newState) {
    state = newState;
  }
}

class FilterState {
  final List<FilterCriteria> filters;
  final List<SortCriteria> sorts;

  FilterState({
    List<FilterCriteria>? filters,
    List<SortCriteria>? sorts,
  })  : filters = filters ?? [],
        sorts = sorts ?? [];
}