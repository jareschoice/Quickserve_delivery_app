import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_client.dart';
import '../../services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Support Chat Screen - AI chatbot with live agent escalation
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  final SocketService _socketService = SocketService();

  String? _ticketId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  String? _userName;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _initChat();
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
    });
  }

  void _setupSocketListeners() {
    _socketService.connect();

    // Listen for incoming messages
    _socketService.on('chat:message', (data) {
      debugPrint('Chat message received: $data');
      if (data != null && mounted) {
        final message = ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: data['message']?['content'] ?? data['content'] ?? '',
          fromRole: data['message']?['fromRole'] ?? data['fromRole'] ?? 'ai',
          from: data['message']?['from'] ?? data['from'] ?? 'QuickBot',
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    });

    // Listen for support responses
    _socketService.on('support:response', (data) {
      debugPrint('Support response: $data');
      if (data != null && mounted) {
        final message = ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: data['content'] ?? '',
          fromRole: 'admin',
          from: data['adminName'] ?? 'Support Agent',
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(message);
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });

    // Listen for typing indicator
    _socketService.on('chat:typing', (data) {
      if (data != null && data['ticketId'] == _ticketId && mounted) {
        setState(() => _isTyping = true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isTyping = false);
        });
      }
    });
  }

  void _removeSocketListeners() {
    _socketService.off('chat:message');
    _socketService.off('support:response');
    _socketService.off('chat:typing');
  }

  Future<void> _initChat() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiClient().postJson('/api/chat/start', {});

      if (response['success'] == true) {
        setState(() {
          _ticketId = response['ticket'];

          // Load existing messages
          final messages = response['messages'] as List? ?? [];
          _messages.clear();
          for (final msg in messages) {
            _messages.add(
              ChatMessageModel(
                id:
                    msg['_id'] ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                content: msg['content'] ?? '',
                fromRole: msg['fromRole'] ?? 'ai',
                from: msg['from'] ?? 'QuickBot',
                timestamp:
                    DateTime.tryParse(msg['createdAt'] ?? '') ?? DateTime.now(),
              ),
            );
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Chat init error: $e');
      // Show welcome message even on error
      setState(() {
        _messages.add(
          ChatMessageModel(
            id: '1',
            content:
                "Hello! 👋 Welcome to QuickServe Support! I'm QuickBot, your AI assistant. How can I help you today?",
            fromRole: 'ai',
            from: 'QuickBot',
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Add user message immediately
    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      fromRole: 'user',
      from: _userName ?? 'Me',
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await ApiClient().postJson('/api/chat/send', {
        'content': text,
        'ticketId': _ticketId,
      });

      if (response['success'] == true) {
        setState(() {
          _ticketId = response['ticketId'];

          // Add AI response
          final aiResponse = response['aiResponse'];
          if (aiResponse != null) {
            _messages.add(
              ChatMessageModel(
                id:
                    aiResponse['_id'] ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                content: aiResponse['content'] ?? '',
                fromRole: aiResponse['fromRole'] ?? 'ai',
                from: aiResponse['from'] ?? 'QuickBot',
                timestamp:
                    DateTime.tryParse(aiResponse['createdAt'] ?? '') ??
                    DateTime.now(),
              ),
            );
          }

          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Send message error: $e');
      // Show error response
      setState(() {
        _messages.add(
          ChatMessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                "I'm sorry, I'm having trouble connecting right now. Please try again in a moment. 🔄",
            fromRole: 'ai',
            from: 'QuickBot',
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _requestAgent() async {
    setState(() => _isSending = true);

    try {
      final response = await ApiClient().postJson('/api/chat/request-agent', {
        'ticketId': _ticketId,
        'reason': 'User requested live support',
      });

      if (!mounted) {
        return;
      }

      if (response['success'] == true) {
        setState(() {
          _ticketId = response['ticketId'];

          final msg = response['message'];
          if (msg != null) {
            _messages.add(
              ChatMessageModel(
                id:
                    msg['_id'] ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                content: msg['content'] ?? '',
                fromRole: msg['fromRole'] ?? 'ai',
                from: msg['from'] ?? 'QuickBot',
                timestamp: DateTime.now(),
              ),
            );
          }
        });
        _scrollToBottom();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A support agent has been notified and will respond shortly!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Request agent error: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to request agent. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text('🤖', style: TextStyle(fontSize: 20)),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QuickServe Support', style: TextStyle(fontSize: 16)),
                Text(
                  'Usually replies instantly',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: _requestAgent,
            tooltip: 'Request Human Agent',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ticket reference
          if (_ticketId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_number,
                    size: 16,
                    color: Color(0xFFFF6B00),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ticket: $_ticketId',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Quick actions
          _buildQuickActions(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.fromRole == 'user';
    final isAdmin = message.fromRole == 'admin';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isAdmin ? Colors.green : const Color(0xFFFF6B00),
              child: Text(
                isAdmin ? '👨‍💼' : '🤖',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFFF6B00)
                    : isAdmin
                    ? Colors.green.shade50
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        isAdmin ? 'Support Agent' : 'QuickBot',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAdmin
                              ? Colors.green
                              : const Color(0xFFFF6B00),
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2196F3),
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFFF6B00),
            child: Text('🤖', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [_buildDot(0), _buildDot(1), _buildDot(2)]),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.3 + value * 0.7),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickAction('📦 Track Order', 'I want to track my order'),
            _buildQuickAction('💳 Payment Issue', 'I have a payment issue'),
            _buildQuickAction(
              '🍽️ Meal Plans',
              'Tell me about meal subscriptions',
            ),
            _buildQuickAction('👨‍💼 Human Agent', null, isAgent: true),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    String? message, {
    bool isAgent = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isAgent) {
          _requestAgent();
        } else if (message != null) {
          _messageController.text = message;
          _sendMessage();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAgent
              ? Colors.green.shade50
              : const Color(0xFFFF6B00).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAgent
                ? Colors.green
                : const Color(0xFFFF6B00).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isAgent ? Colors.green : const Color(0xFFFF6B00),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isSending ? Colors.grey : const Color(0xFFFF6B00),
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFFFF6B00)),
              title: const Text('Restart Chat'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                  _ticketId = null;
                });
                _initChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.green),
              title: const Text('Request Human Agent'),
              onTap: () {
                Navigator.pop(context);
                _requestAgent();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('View Previous Tickets'),
              onTap: () {
                Navigator.pop(context);
                _showTicketHistory();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTicketHistory() async {
    try {
      final response = await ApiClient().getJson('/api/chat/tickets');
      final tickets = response['tickets'] as List? ?? [];

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Previous Tickets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (tickets.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No previous tickets')),
                )
              else
                ...tickets
                    .take(5)
                    .map(
                      (ticket) => ListTile(
                        leading: Icon(
                          ticket['status'] == 'closed'
                              ? Icons.check_circle
                              : Icons.pending,
                          color: ticket['status'] == 'closed'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(ticket['ticketId'] ?? 'Unknown'),
                        subtitle: Text(ticket['status'] ?? 'unknown'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _ticketId = ticket['ticketId'];
                          });
                          _initChat();
                        },
                      ),
                    ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Load tickets error: $e');
    }
  }
}

class ChatMessageModel {
  final String id;
  final String content;
  final String fromRole;
  final String from;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.fromRole,
    required this.from,
    required this.timestamp,
  });
}
