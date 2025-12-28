import 'package:flutter/material.dart';
import '../models/events/event_model.dart';
import '../services/event_service.dart';
import 'package:logger/logger.dart';

class EventViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();
  final Logger _logger = Logger();

  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  List<EventModel> get events => _filteredEvents.isEmpty && _searchQuery.isEmpty
      ? _events
      : _filteredEvents;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  EventModel? _selectedEvent;
  EventModel? get selectedEvent => _selectedEvent;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterEvents();
  }

  void _filterEvents() {
    if (_searchQuery.isEmpty) {
      _filteredEvents = _events;
    } else {
      _filteredEvents = _events.where((event) {
        final title = event.eventTitle.toLowerCase();
        final desc = event.eventDesc.toLowerCase();
        final cat = (event.categoryTitle ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) ||
            desc.contains(query) ||
            cat.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventService.getEvents();
      _filterEvents(); // Apply filter to newly fetched events
    } catch (e) {
      _logger.e('Error fetching events: $e');
      _errorMessage = 'Etkinlikler yüklenirken bir hata oluştu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEventDetail(int eventId) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedEvent = null; // Clear previous selection
    notifyListeners();

    try {
      _selectedEvent = await _eventService.getEventDetail(eventId);
    } catch (e) {
      _logger.e('Error fetching event detail: $e');
      _errorMessage = 'Etkinlik detayı yüklenirken bir hata oluştu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
