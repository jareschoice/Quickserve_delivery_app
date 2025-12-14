import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rider Chat Screen - Real-time chat between customer and rider during delivery
class RiderChatScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? rider;

  const RiderChatScreen({super.key, required this.orderId, this.rider});

  @override
  State<RiderChatScreen> createState() => _RiderChatScreenState();
}

class _RiderChatScreenState extends State<RiderChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<RiderChatMessage> _messages = [];
  final SocketService _socketService = SocketService();

  bool _isLoading = true;
  bool _isSending = false;
  bool _isRiderTyping = false;
  String? _userName;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadChatHistory();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _removeSocketListeners();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Customer';
      // userId stored in prefs but not needed as local state
    });
  }

  void _setupSocketListeners() {
    _socketService.connect();

    // Join order-specific chat room
    _socketService.joinRoom('order:${widget.orderId}:chat');

    // Listen for incoming messages
    _socketService.on('rider:chat:message', (data) {
      debugPrint('Rider chat message received: $data');
      if (data != null && data['orderId'] == widget.orderId && mounted) {
        final message = RiderChatMessage(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          content: data['content'] ?? data['message'] ?? '',
          fromRole: data['fromRole'] ?? 'rider',
          senderName: data['senderName'] ?? 'Rider',
          timestamp:
              DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
        );
        setState(() {
          _messages.add(message);
          _isRiderTyping = false;
        });
        _scrollToBottom();
      }
    });

    // Listen for typing indicator
    _socketService.on('rider:chat:typing', (data) {
      if (data != null && data['orderId'] == widget.orderId && mounted) {
        setState(() => _isRiderTyping = true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isRiderTyping = false);
        });
      }
    });

    // Emit join event
    _socketService.emit('rider:chat:join', {'orderId': widget.orderId});
  }

  void _removeSocketListeners() {
    _socketService.leaveRoom('order:${widget.orderId}:chat');
    _socketService.off('rider:chat:message');
    _socketService.off('rider:chat:typing');
  }

  Future<void> _loadChatHistory() async {
    try {
      final response = await ApiClient.get('/orders/${widget.orderId}/chat');
      if (response['success'] == true && response['messages'] != null) {
        final messages = (response['messages'] as List)
            .map(
              (m) => RiderChatMessage(
                id: m['_id'] ?? m['id'] ?? '',
                content: m['content'] ?? m['message'] ?? '',
                fromRole: m['fromRole'] ?? 'customer',
                senderName: m['senderName'] ?? 'Unknown',
                timestamp:
                    DateTime.tryParse(m['createdAt'] ?? m['timestamp'] ?? '') ??
                    DateTime.now(),
              ),
            )
            .toList();
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(messages);
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        // No chat history yet, that's okay
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Add message optimistically
    final tempMessage = RiderChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      fromRole: 'customer',
      senderName: _userName ?? 'You',
      timestamp: DateTime.now(),
      isSending: true,
    );
    setState(() => _messages.add(tempMessage));
    _scrollToBottom();

    try {
      // Send via API
      final response = await ApiClient.post('/orders/${widget.orderId}/chat', {
        'content': content,
        'fromRole': 'customer',
        'senderName': _userName ?? 'Customer',
      });

      // Also emit via socket for real-time
      _socketService.emit('rider:chat:send', {
        'orderId': widget.orderId,
        'content': content,
        'fromRole': 'customer',
        'senderName': _userName ?? 'Customer',
      });

      if (mounted) {
        setState(() {
          // Update temp message to sent
          final idx = _messages.indexWhere((m) => m.id == tempMessage.id);
          if (idx != -1) {
            _messages[idx] = RiderChatMessage(
              id: response['message']?['_id'] ?? tempMessage.id,
              content: content,
              fromRole: 'customer',
              senderName: _userName ?? 'You',
              timestamp: DateTime.now(),
              isSending: false,
            );
          }
          _isSending = false;
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() {
          // Mark message as failed
          final idx = _messages.indexWhere((m) => m.id == tempMessage.id);
          if (idx != -1) {
            _messages[idx] = RiderChatMessage(
              id: tempMessage.id,
              content: content,
              fromRole: 'customer',
              senderName: _userName ?? 'You',
              timestamp: DateTime.now(),
              isSending: false,
              isFailed: true,
            );
          }
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Tap to retry.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _emitTyping() {
    _socketService.emit('rider:chat:typing', {
      'orderId': widget.orderId,
      'fromRole': 'customer',
    });
  }

  @override
  Widget build(BuildContext context) {
    final riderName =
        widget.rider?['name'] ?? widget.rider?['fullName'] ?? 'Rider';
    final riderPhone = widget.rider?['phone'] ?? widget.rider?['phoneNumber'];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(riderName, style: const TextStyle(fontSize: 16)),
            Text(
              _isRiderTyping ? 'typing...' : 'Your Delivery Rider',
              style: TextStyle(
                fontSize: 12,
                color: _isRiderTyping ? Colors.greenAccent : Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        actions: [
          if (riderPhone != null)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () async {
                final Uri phoneUri = Uri(scheme: 'tel', path: riderPhone);
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick message chips
          _buildQuickMessageChips(),

          // Chat messages
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                  )
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isRiderTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isRiderTyping && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildQuickMessageChips() {
    final quickMessages = [
      'Where are you?',
      'I\'m outside',
      'Call me please',
      'Thank you!',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: quickMessages.map((msg) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(msg, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.white,
                onPressed: () {
                  _messageController.text = msg;
                  _sendMessage();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to your rider',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(RiderChatMessage message) {
    final isMe = message.fromRole == 'customer';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF6B00).withValues(alpha: 0.1),
              child: const Icon(
                Icons.delivery_dining,
                size: 18,
                color: Color(0xFFFF6B00),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFF6B00) : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      if (isMe && message.isSending) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ] else if (isMe && message.isFailed) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ] else if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done, size: 14, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            child: const Icon(
              Icons.delivery_dining,
              size: 18,
              color: Color(0xFFFF6B00),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(150),
                const SizedBox(width: 4),
                _buildTypingDot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[400]?.withValues(alpha: 0.5 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _emitTyping(),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B00),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isSending ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
              ),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Chat message model for rider chat
class RiderChatMessage {
  final String id;
  final String content;
  final String fromRole; // 'customer' or 'rider'
  final String senderName;
  final DateTime timestamp;
  final bool isSending;
  final bool isFailed;

  RiderChatMessage({
    required this.id,
    required this.content,
    required this.fromRole,
    required this.senderName,
    required this.timestamp,
    this.isSending = false,
    this.isFailed = false,
  });
}
