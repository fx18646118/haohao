import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/membership_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/quota_dialogs.dart';
import '../auth/login_screen.dart';
import '../membership/membership_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const ChatScreen(),
    const LibraryScreen(),
    const DiscoverScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: '创作',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: '作品',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: '发现',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 创作页面（对话式AI音乐创作）
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // 添加欢迎消息
    _messages.add(
      ChatMessage(
        isUser: false,
        message: '你好！我是皓皓同学，你的AI音乐创作助手。\n\n告诉我你想创作什么样的音乐？比如：\n• 写一首关于失恋的流行歌\n• 生成一段轻快的背景音乐\n• 为我的视频配个BGM',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // 检查登录和次数
    final membershipProvider = context.read<MembershipProvider>();
    final canProceed = await checkAndShowQuotaDialog(
      context,
      isLoggedIn: membershipProvider.isLoggedIn,
      remainingQuota: membershipProvider.remainingGenerations,
    );
    
    if (!canProceed) return;

    // 消耗次数
    final success = await membershipProvider.consumeGeneration();
    if (!success) {
      if (mounted) {
        showQuotaExceededDialog(context);
      }
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        isUser: true,
        message: message,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isGenerating = true;
    });

    _scrollToBottom();

    // 模拟AI回复
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: '好的，我来为你创作一首关于"$message"的歌曲。\n\n请稍等，我正在生成歌词、作曲和编曲...',
          timestamp: DateTime.now(),
          isGenerating: true,
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
      appBar: AppBar(
        title: const Text('AI音乐创作'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 新建对话
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 快捷功能按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickButton('🎵 流行歌曲', () {}),
                  const SizedBox(width: 8),
                  _buildQuickButton('🎸 摇滚风格', () {}),
                  const SizedBox(width: 8),
                  _buildQuickButton('🎹 轻音乐', () {}),
                  const SizedBox(width: 8),
                  _buildQuickButton('🎤 说唱', () {}),
                  const SizedBox(width: 8),
                  _buildQuickButton('🎬 BGM', () {}),
                ],
              ),
            ),
          ),
          // 多模态输入选项
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildMediaButton(Icons.image, '图片', () {}),
                const SizedBox(width: 12),
                _buildMediaButton(Icons.videocam, '视频', () {}),
                const SizedBox(width: 12),
                _buildMediaButton(Icons.mic, '音频', () {}),
              ],
            ),
          ),
          // 聊天消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(_messages[index]);
              },
            ),
          ),
          // 输入框
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      // 附件选择
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '描述你想创作的音乐...',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF6C5DD3)
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: !message.isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: message.isUser ? Colors.white : null,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            if (message.isGenerating) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 作品库页面
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的作品'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return _buildMusicCard(
            '未命名作品 ${index + 1}',
            '流行 • 2:34',
            null, // 使用默认占位符
          );
        },
      ),
    );
  }

  Widget _buildMusicCard(String title, String subtitle, String? coverUrl) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5DD3), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.music_note,
                  size: 48,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 发现页面
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('热门风格'),
          const SizedBox(height: 12),
          _buildStyleGrid(),
          const SizedBox(height: 24),
          _buildSectionTitle('推荐作品'),
          const SizedBox(height: 12),
          _buildRecommendedList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStyleGrid() {
    final styles = [
      {'name': '流行', 'icon': Icons.star},
      {'name': '摇滚', 'icon': Icons.electric_bolt},
      {'name': '电子', 'icon': Icons.waves},
      {'name': '古典', 'icon': Icons.piano},
      {'name': '爵士', 'icon': Icons.nightlife},
      {'name': '说唱', 'icon': Icons.mic},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5DD3), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                styles[index]['icon'] as IconData,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Text(
                styles[index]['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecommendedList() {
    return Column(
      children: List.generate(
        5,
        (index) => ListTile(
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5DD3), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text('推荐作品 ${index + 1}'),
          subtitle: Text('${(index + 1) * 1234} 次播放'),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_fill),
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}

// 个人中心页面
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<MembershipProvider>(
        builder: (context, membershipProvider, child) {
          final user = membershipProvider.user;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 用户信息
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!membershipProvider.isLoggedIn) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: membershipProvider.isMember
                              ? LinearGradient(
                                  colors: [
                                    membershipProvider.membershipLevel.color.withOpacity(0.8),
                                    membershipProvider.membershipLevel.color,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: user?.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.avatarUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.nickname ?? (membershipProvider.isLoggedIn ? '音乐创作者' : '点击登录'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (membershipProvider.isLoggedIn) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: membershipProvider.isMember
                              ? LinearGradient(
                                  colors: [
                                    membershipProvider.membershipLevel.color,
                                    membershipProvider.membershipLevel.color.withOpacity(0.8),
                                  ],
                                )
                              : null,
                          color: membershipProvider.isMember ? null : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              membershipProvider.membershipLevel.icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              membershipProvider.membershipLevel.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '今日剩余 ${membershipProvider.remainingGenerations} 次生成额度',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '登录后享受更多特权',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 统计卡片
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('作品', '${user?.totalGenerations ?? 0}'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('剩余', '${membershipProvider.remainingGenerations}'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('等级', membershipProvider.membershipLevel.icon),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // 功能列表
              _buildMenuItem(
                Icons.workspace_premium,
                '会员中心',
                membershipProvider.isMember ? '管理您的会员' : '解锁更多功能',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MembershipScreen(),
                  ),
                ),
              ),
              if (membershipProvider.isLoggedIn)
                _buildMenuItem(
                  Icons.logout,
                  '退出登录',
                  '退出当前账号',
                  onTap: () => _showLogoutDialog(context, membershipProvider),
                ),
              _buildMenuItem(Icons.palette, '主题设置', '切换深色/浅色模式'),
              _buildMenuItem(Icons.help_outline, '帮助与反馈', '常见问题解答'),
              _buildMenuItem(Icons.info_outline, '关于我们', 'v1.0.0'),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, MembershipProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '确认退出',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '确定要退出登录吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.logout();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C5DD3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6C5DD3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6C5DD3)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// 聊天消息模型
class ChatMessage {
  final bool isUser;
  final String message;
  final DateTime timestamp;
  final bool isGenerating;

  ChatMessage({
    required this.isUser,
    required this.message,
    required this.timestamp,
    this.isGenerating = false,
  });
}