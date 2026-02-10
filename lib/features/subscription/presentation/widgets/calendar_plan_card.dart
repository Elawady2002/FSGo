import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/subscription_entity.dart';
import 'calendar_plan_card_views/plan_calendar_view.dart';
import 'calendar_plan_card_views/plan_details_view.dart';
import 'calendar_plan_card_views/plan_time_selection_view.dart';

enum CardViewState { details, calendar, timeSelection }

class CalendarPlanCard extends ConsumerStatefulWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final Color accentColor;
  final SubscriptionPlanType planType;
  final void Function(SubscriptionScheduleParams? params) onSubscribe;

  const CalendarPlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isPopular,
    required this.accentColor,
    required this.planType,
    required this.onSubscribe,
  });

  @override
  ConsumerState<CalendarPlanCard> createState() => _CalendarPlanCardState();
}

class _CalendarPlanCardState extends ConsumerState<CalendarPlanCard> {
  CardViewState _currentView = CardViewState.details;
  DateTime? _selectedDate;

  DateTime get _startDate => DateTime.now();
  DateTime get _endDate =>
      _startDate.add(Duration(days: widget.planType.durationDays));

  void _onCalendarIconTap() {
    setState(() {
      _currentView = CardViewState.calendar;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _currentView = CardViewState.timeSelection;
    });
  }

  void _onBackToCalendar() {
    setState(() {
      _currentView = CardViewState.calendar;
      _selectedDate = null;
    });
  }

  void _onBackToDetails() {
    setState(() {
      _currentView = CardViewState.details;
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark charcoal
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        child: _buildCurrentView(),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CardViewState.details:
        return PlanDetailsView(
          title: widget.title,
          price: widget.price,
          period: widget.period,
          features: widget.features,
          isPopular: widget.isPopular,
          accentColor: widget.accentColor,
          onCalendarTap: _onCalendarIconTap,
          onSubscribeTap: () => widget.onSubscribe(null),
        );
      case CardViewState.calendar:
        return PlanCalendarView(
          startDate: _startDate,
          endDate: _endDate,
          accentColor: widget.accentColor,
          onDateSelected: _onDateSelected,
          onBack: _onBackToDetails,
        );
      case CardViewState.timeSelection:
        final user = ref.watch(authProvider).valueOrNull;
        return PlanTimeSelectionView(
          selectedDate: _selectedDate!,
          accentColor: widget.accentColor,
          universityId: user?.universityId,
          onConfirm: widget.onSubscribe,
          onBack: _onBackToCalendar,
        );
    }
  }
}
