import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/courses_notifier.dart';
import '../providers/courses_providers.dart';
import '../providers/courses_state.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/course_card.dart';

class CoursesPage extends ConsumerStatefulWidget {
  const CoursesPage({super.key});

  @override
  ConsumerState<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends ConsumerState<CoursesPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 240) {
      ref.read(coursesNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coursesNotifierProvider);
    final notifier = ref.read(coursesNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          CategoryFilterBar(
            selected: state.category,
            onChanged: notifier.filterByCategory,
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(CoursesState state, CoursesNotifier notifier) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingIndicator();
    }
    if (state.failure != null && state.items.isEmpty) {
      return ErrorView(
        message: state.failure!.displayMessage,
        onRetry: notifier.refresh,
      );
    }
    if (state.isEmpty) {
      return const EmptyView(message: 'No courses yet.');
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: GridView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingIndicator(size: 24),
            );
          }
          final c = state.items[index];
          return CourseCard(
            course: c,
            onTap: () => context.goNamed(
              RouteNames.courseDetail,
              pathParameters: {'id': c.id},
            ),
          );
        },
      ),
    );
  }
}
