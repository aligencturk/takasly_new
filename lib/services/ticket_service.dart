import '../core/constants/api_constants.dart';
import '../models/tickets/ticket_model.dart';
import 'api_service.dart';

class TicketService {
  final ApiService _apiService = ApiService();

  Future<TicketListResponse> getUserTickets(int page, String userToken) async {
    try {
      final String url =
          '${ApiConstants.userTickets}?userToken=$userToken&page=$page';
      final response = await _apiService.get(url);
      return TicketListResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TicketMessagesResponse> getTicketMessages(
    int ticketID,
    int page,
    String userToken,
  ) async {
    try {
      final String url =
          '${ApiConstants.ticketMessages}?userToken=$userToken&ticketID=$ticketID&page=$page';
      final response = await _apiService.get(url);
      return TicketMessagesResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TicketDetailResponse> getTicketDetail(
    int ticketID,
    String userToken,
  ) async {
    try {
      final String url =
          '${ApiConstants.ticketDetail}?userToken=$userToken&ticketID=$ticketID';
      final response = await _apiService.get(url);
      return TicketDetailResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
