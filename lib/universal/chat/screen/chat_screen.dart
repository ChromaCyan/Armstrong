import 'package:armstrong/universal/blocs/appointment/appointment_new_bloc.dart';
import 'package:flutter/material.dart';
import 'package:armstrong/services/api.dart';
import 'package:armstrong/services/socket_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:armstrong/config/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:armstrong/universal/blocs/appointment/appointment_bloc.dart';
import 'package:armstrong/widgets/forms/appointment_booking_form.dart';
import 'package:armstrong/universal/chat/screen/chat_bubble.dart';
import 'package:armstrong/universal/chat/screen/text_n_send.dart';
import 'package:armstrong/helpers/storage_helpers.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String recipientName;
  final String recipientId;

  ChatScreen({
    required this.chatId,
    required this.recipientName,
    required this.recipientId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiRepository _apiRepository = ApiRepository();
  final SocketService _socketService = SocketService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  String? _userId;
  bool _isScrolledUp = false;
  bool _isLoading = true;
  bool _isSpecialist = false;

  @override
  void initState() {
    super.initState();
    _initializeUserIdAndLoadData();

    _scrollController.addListener(() {
      final isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50;
      setState(() {
        _isScrolledUp = !isAtBottom;
      });
    });
  }

  void _initializeUserIdAndLoadData() async {
    _userId = await StorageHelper.getUserId();
    String? userType = await StorageHelper.getUserType();

    if (_userId != null && userType != null) {
      setState(() {
        _isSpecialist = userType.toLowerCase() == 'specialist';
      });
    }

    _loadMessages();
  }

  void _initializeSocket() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      _socketService.connect(token);
      _socketService.onMessageReceived = (message) {
        setState(() {
          _messages.add(message);
        });

        if (!_isScrolledUp) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _scrollToBottom();
          });
        }
      };
    }
  }

  void _loadMessages() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      try {
        final messages =
            await _apiRepository.getChatHistory(widget.chatId, token);
        setState(() {
          _messages = messages.map((message) {
            return {
              'senderId': message['sender']['_id'],
              'content': message['content'],
              'timestamp': message['timestamp'],
              'status': message['status'] ?? 'sent',
            };
          }).toList();
          _isLoading = false;
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      } catch (e) {
        print("Error loading messages: $e");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sendMessage() async {
    final token = await _storage.read(key: 'token');
    if (token != null && _controller.text.trim().isNotEmpty) {
      final messageContent = _controller.text.trim();
      final message = {
        'senderId': _userId,
        'content': messageContent,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sent',
      };

      setState(() {
        _messages.add(message);
        _controller.clear();
      });

      try {
        await _apiRepository.sendMessage(widget.chatId, messageContent, token);
        _socketService.sendMessage(
            token, widget.recipientId, messageContent, widget.chatId);

        setState(() {
          message['status'] = 'delivered';
        });
      } catch (e) {
        print("Error sending message: $e");
      }
    }
  }

  void _bookAppointment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return BlocProvider.value(
          value: BlocProvider.of<TimeSlotBloc>(context),
          child: AppointmentBookingForm(specialistId: widget.recipientId),
        );
      },
    );
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('hh:mm a, MMM d').format(dateTime);
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.recipientName}")),
      body: Column(
        children: <Widget>[
          // Create Appointment Button
          if (!_isSpecialist)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _bookAppointment(context),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  shadowColor: Colors.black.withOpacity(0.2),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      "Create Appointment Now",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Chat Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 10),
                            Text(
                              "No messages yet",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];

                          return ChatBubble(
                            content: message['content'] ?? 'No message',
                            timestamp: _formatTimestamp(message['timestamp']),
                            status: message['status'] ?? 'sent',
                            isSender: message['senderId'] == _userId,
                            senderName: widget.recipientName,
                          );
                        },
                      ),
          ),

          TextNSend(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}
