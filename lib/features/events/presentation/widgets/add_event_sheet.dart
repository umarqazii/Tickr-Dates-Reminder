import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/event_repository.dart';
import '../../domain/tickr_event.dart';

/// Opens the add/edit sheet with a rounded surface; [backgroundColor] is transparent so this shows through.
Future<void> showAddEventSheet(BuildContext context, {TickrEvent? existingEvent}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddEventSheet(existingEvent: existingEvent),
  );
}

class AddEventSheet extends ConsumerStatefulWidget {
  final TickrEvent? existingEvent;

  const AddEventSheet({super.key, this.existingEvent});

  @override
  ConsumerState<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<AddEventSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late bool _isRecurring;

  @override
  void initState() {
    super.initState();
    final event = widget.existingEvent;

    _titleController = TextEditingController(text: event?.title ?? '');
    _notesController = TextEditingController(text: event?.notes ?? '');
    _selectedDate = event?.eventDate.toLocal() ?? DateTime.now();
    _isRecurring = event?.isRecurring ?? false;

    if (widget.existingEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: AppColors.onPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveEvent() {
    final title = _titleController.text.trim();
    final notes = _notesController.text;
    if (title.isEmpty) return;

    final repo = ref.read(eventRepositoryProvider);

    if (widget.existingEvent == null) {
      repo.saveEvent(
        title: title,
        notes: notes,
        eventDate: _selectedDate,
        isRecurring: _isRecurring,
      );
    } else {
      repo.updateEvent(
        event: widget.existingEvent!,
        title: title,
        notes: notes,
        eventDate: _selectedDate,
        isRecurring: _isRecurring,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEditing = widget.existingEvent != null;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomInset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEditing ? 'Edit moment' : 'New moment',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: widget.existingEvent == null,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'What are we remembering?',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, color: AppColors.primaryBright, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  DateFormat.yMMMd().format(_selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.autorenew_rounded, size: 22, color: AppColors.recurring.withValues(alpha: 0.9)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Remind Every Year',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _isRecurring,
                      activeColor: AppColors.primaryBright,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                isEditing ? 'Edit Note' : 'Notes (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                autofocus: widget.existingEvent == null,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Further details of the event',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                ),
              ),

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saveEvent,
                child: Text(isEditing ? 'Save changes' : 'Add to timeline'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
