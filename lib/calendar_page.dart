import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import 'package:smx/event_edit_page.dart';

import 'package:intl/intl.dart';

const Uuid uuid = Uuid();

class Event {
  final String id;
  String title;
  DateTime dateTime;
  String location;
  String notes;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    this.location = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'location': location,
        'notes': notes,
      };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        title: json['title'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        location: json['location'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  @override
  String toString() => title;
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ValueNotifier<List<Event>> _allEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _allEvents = ValueNotifier([]);
    _loadEvents();
  }

  @override
  void dispose() {
    _allEvents.dispose();
    super.dispose();
  }

  Future<File> _getEventsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/events.json');
  }

  Future<void> _loadEvents() async {
    final file = await _getEventsFile();
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        final List<Event> allEvents = [];
        jsonMap.forEach((key, value) {
          final events = (value as List).map((e) => Event.fromJson(e)).toList();
          allEvents.addAll(events);
        });
        allEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        _allEvents.value = allEvents;

        setState(() {
          _events = jsonMap.map((key, value) {
            final date = DateTime.parse(key);
            final events = (value as List).map((e) => Event.fromJson(e)).toList();
            return MapEntry(date, events);
          });
        });
      } catch (e) {
        // Handle potential decoding errors by starting fresh
        _events = {};
        _allEvents.value = [];
      }
    }
  }

  Future<void> _saveEvents() async {
    final file = await _getEventsFile();
    final jsonMap = _events.map((key, value) {
      final dateString = key.toIso8601String();
      final eventsJson = value.map((e) => e.toJson()).toList();
      return MapEntry(dateString, eventsJson);
    });
    await file.writeAsString(jsonEncode(jsonMap));
    _loadEvents(); // Reload all events to update the list
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _addEvent() async {
    final newEvent = await Navigator.of(context).push<Event>(
      MaterialPageRoute(
        builder: (_) => EventEditPage(selectedDate: _selectedDay!),
      ),
    );

    if (newEvent != null) {
      final day = DateTime.utc(newEvent.dateTime.year, newEvent.dateTime.month, newEvent.dateTime.day);
      
      setState(() {
        if (_events[day] == null) {
          _events[day] = [];
        }
        _events[day]!.add(newEvent);
      });

      await _saveEvents();
    }
  }

  Future<void> _editEvent(Event event) async {
    final updatedEvent = await Navigator.of(context).push<Event>(
      MaterialPageRoute(
        builder: (_) => EventEditPage(event: event, selectedDate: event.dateTime),
      ),
    );

    if (updatedEvent != null) {
      final oldDay = DateTime.utc(event.dateTime.year, event.dateTime.month, event.dateTime.day);
      final newDay = DateTime.utc(updatedEvent.dateTime.year, updatedEvent.dateTime.month, updatedEvent.dateTime.day);

      setState(() {
        _events[oldDay]?.removeWhere((e) => e.id == event.id);
        if (_events[oldDay]?.isEmpty ?? false) {
          _events.remove(oldDay);
        }

        if (_events[newDay] == null) {
          _events[newDay] = [];
        }
        _events[newDay]!.add(updatedEvent);
      });

      await _saveEvents();
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final day = DateTime.utc(event.dateTime.year, event.dateTime.month, event.dateTime.day);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Evento'),
        content: Text('Sei sicuro di voler eliminare "${event.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Elimina', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
        setState(() {
        _events[day]?.removeWhere((e) => e.id == event.id);
        if (_events[day]?.isEmpty ?? false) {
            _events.remove(day);
        }
        });
        await _saveEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        heroTag: 'addEventButton',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            locale: 'it_IT',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                  _focusedDay = focusedDay;
              });
            },
            daysOfWeekHeight: 30.0, // Fixed height for days of week

            // Style for the days of the week header
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
              weekendStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),

            // General calendar styling
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              // Event marker style
              markerDecoration: BoxDecoration(
                color: isDarkMode ? Colors.yellowAccent.withOpacity(0.8) : Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              // Make weekend text more prominent
              weekendTextStyle: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.9)),
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20.0),
              ),
              formatButtonTextStyle: const TextStyle(color: Colors.white),
              formatButtonShowsNext: false,
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _allEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nessun evento ancora.\nPremi + per aggiungerne uno.',
                      textAlign: TextAlign.center,
                       style: TextStyle(fontSize: 18, color: Colors.grey)
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        title: Text(event.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime)),
                            const SizedBox(height: 4),
                            Text('Luogo: ${event.location}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editEvent(event),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteEvent(event),
                            ),
                          ],
                        ),
                        onTap: () => _editEvent(event),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
