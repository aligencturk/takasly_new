import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/tickets/ticket_model.dart';
import '../services/ticket_service.dart';
import '../services/api_service.dart';

class TicketViewModel extends ChangeNotifier {
  final TicketService _ticketService = TicketService();
  final Logger _logger = Logger();

  List<Ticket> tickets = [];
  bool isLoading = false;
  bool isLoadMoreRunning = false;
  bool isLastPage = false;
  int currentPage = 1;
  String? errorMessage;
  String? emptyMessage;

  // Chat/Messages State
  List<TicketMessage> messages = [];
  bool isMessageLoading = false;
  bool isMessageLastPage = false;
  int currentMessagePage = 1;
  String? messageErrorMessage;

  // Ticket Detail State (For Chat Banner Context)
  TicketDetailData? currentTicketDetail;
  bool isDetailLoading = false;
  String? detailErrorMessage;

  Future<void> fetchTickets(String userToken, {bool isRefresh = false}) async {
    if (isLoading) return;
    if (isLoadMoreRunning) return;
    if (isLastPage && !isRefresh) return;

    if (isRefresh) {
      isLoading = true;
      isLastPage = false;
      currentPage = 1;
      errorMessage = null;
      tickets.clear();
      notifyListeners();
    } else {
      isLoadMoreRunning = true;
      notifyListeners();
    }

    try {
      final response = await _ticketService.getUserTickets(
        currentPage,
        userToken,
      );

      if (response.success == true && response.data != null) {
        final newTickets = response.data!.tickets ?? [];

        if (isRefresh) {
          tickets = newTickets;
          emptyMessage = response.data!.emptyMessage;
        } else {
          tickets.addAll(newTickets);
        }

        // Pagination Logic
        if (newTickets.isEmpty) {
          isLastPage = true;
        } else {
          // If totalPages is available, use it. Otherwise rely on 410 or empty list.
          if (response.data!.totalPages != null) {
            if (currentPage >= response.data!.totalPages!) {
              isLastPage = true;
            } else {
              currentPage++;
            }
          } else {
            // Fallback if totalPages is not reliable or missing
            if (response.data!.hasNextPage == false) {
              isLastPage = true;
            } else {
              currentPage++;
            }
          }
        }
      } else {
        errorMessage = response.message ?? "Mesajlar yüklenemedi.";
      }
    } catch (e) {
      if (e is EndOfListException) {
        _logger.i("Ticket listesi sonuna gelindi (410).");
        isLastPage = true;
      } else {
        errorMessage = "Bir hata oluştu: $e";
        _logger.e("Hata oluştu", error: e);
      }
    } finally {
      isLoading = false;
      isLoadMoreRunning = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(
    int ticketID,
    String userToken, {
    bool isRefresh = false,
    bool isSilent = false,
  }) async {
    if (isMessageLoading) return;
    if (isMessageLastPage && !isRefresh) return;

    if (isRefresh) {
      if (!isSilent) {
        isMessageLoading = true;
        notifyListeners();
      }
      isMessageLastPage = false;
      currentMessagePage = 1;
      messageErrorMessage = null;
      // Do not clear messages immediately if silent, to avoid flicker
      if (!isSilent) {
        messages.clear();
      }
    } else {
      isMessageLoading = true;
      notifyListeners();
    }

    try {
      final response = await _ticketService.getTicketMessages(
        ticketID,
        currentMessagePage,
        userToken,
      );

      if (response.success == true && response.data != null) {
        final newMessages = response.data!.messages ?? [];

        if (isRefresh) {
          messages = newMessages;
        } else {
          messages.addAll(newMessages);
        }

        if (newMessages.isEmpty) {
          isMessageLastPage = true;
        } else {
          if (response.data!.totalPages != null) {
            if (currentMessagePage >= response.data!.totalPages!) {
              isMessageLastPage = true;
            } else {
              currentMessagePage++;
            }
          } else {
            if (response.data!.hasNextPage == false) {
              isMessageLastPage = true;
            } else {
              currentMessagePage++;
            }
          }
        }
      } else {
        messageErrorMessage = response.message ?? "Mesajlar yüklenemedi.";
      }
    } catch (e) {
      if (e is EndOfListException) {
        _logger.i("Mesaj listesi sonuna gelindi (410).");
        isMessageLastPage = true;
      } else {
        messageErrorMessage = "Bir hata oluştu: $e";
        _logger.e("Mesaj Hata", error: e);
      }
    } finally {
      if (!isSilent) {
        isMessageLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchTicketDetail(int ticketID, String userToken) async {
    isDetailLoading = true;
    detailErrorMessage = null;
    notifyListeners();

    try {
      final response = await _ticketService.getTicketDetail(
        ticketID,
        userToken,
      );
      if (response.success == true && response.data != null) {
        currentTicketDetail = response.data;
      } else {
        detailErrorMessage = response.message ?? "Detay yüklenemedi";
      }
    } catch (e) {
      detailErrorMessage = "Bir hata oluştu: $e";
      _logger.e("Ticket Detail Hata", error: e);
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  // Send Message State
  bool isSendingMessage = false;

  Future<bool> sendMessage(
    int ticketID,
    String userToken,
    String message,
  ) async {
    if (isSendingMessage) return false;

    isSendingMessage = true;
    notifyListeners();

    try {
      final success = await _ticketService.sendMessage(
        userToken,
        ticketID,
        message,
      );
      if (success) {
        // Option A: Refresh messages list
        await fetchMessages(ticketID, userToken, isRefresh: true);

        // Option B: Optimistically append message (Requires creating a TicketMessage object)
        // For now, refreshing is safer to ensure we get the full server-side object (like ID, timestamp)
        return true;
      } else {
        messageErrorMessage = "Mesaj gönderilemedi.";
        return false;
      }
    } catch (e) {
      messageErrorMessage = "Mesaj gönderilirken hata: $e";
      _logger.e("Send Message Error", error: e);
      return false;
    } finally {
      isSendingMessage = false;
      notifyListeners();
    }
  }
}
