import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/event_repository.dart';
import '../../domain/tickr_event.dart'; // Add this import

class AddEventSheet extends ConsumerStatefulWidget {
  // Add an optional existing event
  final TickrEvent? existingEvent;

  const AddEventSheet({super.key, this.existingEvent});

  @override
  ConsumerState<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<AddEventSheet> {
  late final TextEditingController _titleController;
  late DateTime _selectedDate;
  late bool _isRecurring;

  @override
  void initState() {
    super.initState();
    // If we passed an event in, pre-fill the form with its exact origin data
    final event = widget.existingEvent;

    _titleController = TextEditingController(text: event?.title ?? '');
    // Convert back from UTC so the user sees their local timezone correctly
    _selectedDate = event?.eventDate.toLocal() ?? DateTime.now();
    _isRecurring = event?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveEvent() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final repo = ref.read(eventRepositoryProvider);

    if (widget.existingEvent == null) {
      // Create new
      repo.saveEvent(
        title: title,
        eventDate: _selectedDate,
        isRecurring: _isRecurring,
      );
    } else {
      // Update existing
      repo.updateEvent(
        event: widget.existingEvent!,
        title: title,
        eventDate: _selectedDate,
        isRecurring: _isRecurring,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // Check if we are updating to change the button text
    final isEditing = widget.existingEvent != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'What are we remembering?',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ActionChip(
                label: Text(DateFormat.yMMMd().format(_selectedDate)),
                avatar: const Icon(Icons.calendar_today, size: 16),
                onPressed: _pickDate,
              ),
              const Spacer(),
              const Text('Yearly'),
              Switch(
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveEvent,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            // Dynamically change the button text
            child: Text(isEditing ? 'Update Event' : 'Save Event'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}