import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smx/calendar_page.dart';

class EventEditPage extends StatefulWidget {
  final Event? event;
  final DateTime selectedDate;

  const EventEditPage({super.key, this.event, required this.selectedDate});

  @override
  _EventEditPageState createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late DateTime _dateTime;
  late String _location;
  late String _notes;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _title = widget.event!.title;
      _dateTime = widget.event!.dateTime;
      _location = widget.event!.location;
      _notes = widget.event!.notes;
    } else {
      _title = '';
      _dateTime = widget.selectedDate;
      _location = '';
      _notes = '';
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _dateTime.hour,
          _dateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time != null) {
      setState(() {
        _dateTime = DateTime(
          _dateTime.year,
          _dateTime.month,
          _dateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Nuovo Evento' : 'Modifica Evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final newEvent = Event(
                  id: widget.event?.id ?? uuid.v4(),
                  title: _title,
                  dateTime: _dateTime,
                  location: _location,
                  notes: _notes,
                );
                Navigator.of(context).pop(newEvent);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: _title,
                        decoration: const InputDecoration(
                          labelText: 'Titolo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci un titolo';
                          }
                          return null;
                        },
                        onSaved: (value) => _title = value!,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Data: ${DateFormat('dd/MM/yyyy').format(_dateTime)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: _pickDate,
                            child: const Text('Cambia'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ora: ${DateFormat('HH:mm').format(_dateTime)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: _pickTime,
                            child: const Text('Cambia'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _location,
                        decoration: const InputDecoration(
                          labelText: 'Luogo',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (value) => _location = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _notes,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          onSaved: (value) => _notes = value ?? '',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
