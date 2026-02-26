// 登录页面 - 支持手机号验证码和微信登录

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/membership_provider.dart';
import '../../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  
  late TabController _tabController;
  bool _isCodeSent = false;
  int _countdown = 60;
  Timer? _timer;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isCodeSent = true;
      _countdown = 60;
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _isCodeSent = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 11) {
      _showError('请输入正确的手机号');
      return;
    }

    final provider = context.read<MembershipProvider>();
    final code = await provider.sendPhoneCode(phone);
    
    if (code != null) {
      _sessionId = code.sessionId;
      _startCountdown();
      _showSuccess('验证码已发送');
    }
  }

  Future<void> _loginWithPhone() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    
    if (phone.isEmpty || phone.length != 11) {
      _showError('请输入正确的手机号');
      return;
    }
    if (code.isEmpty || code.length != 6) {
      _showError('请输入6位验证码');
      return;
    }
    if (_sessionId == null) {
      _showError('请先获取验证码');
      return;
    }

    final provider = context.read<MembershipProvider>();
    final success = await provider.loginWithPhone(phone, code, _sessionId!);
    
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _loginWithWechat() async {
    // 这里需要集成微信SDK
    // 示例代码：
    // final result = await Fluwx.sendWeChatAuth(
    //   scope: 'snsapi_userinfo',
    //   state: 'tunee_login',
    // );
    
    // 模拟微信登录成功
    _showError('请先集成微信SDK');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部返回按钮
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              
              // Logo和标题
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '皓皓同学',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI音乐创作',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 登录表单
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tab切换
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white.withOpacity(0.5),
                          tabs: const [
                            Tab(text: '手机号登录'),
                            Tab(text: '微信登录'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Tab内容
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPhoneLoginForm(),
                            _buildWechatLoginForm(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneLoginForm() {
    return Consumer<MembershipProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // 手机号输入
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '请输入手机号',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.phone, color: AppTheme.greyText),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 验证码输入
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '请输入验证码',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.greyText),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    // 获取验证码按钮
                    GestureDetector(
                      onTap: _isCodeSent ? null : _sendCode,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: _isCodeSent 
                              ? null 
                              : AppTheme.primaryGradient,
                          color: _isCodeSent 
                              ? Colors.white.withOpacity(0.1) 
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isCodeSent ? '$_countdown秒' : '获取验证码',
                          style: TextStyle(
                            color: _isCodeSent 
                                ? Colors.white.withOpacity(0.5) 
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (provider.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _loginWithPhone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 协议提示
              Text.rich(
                TextSpan(
                  text: '登录即表示同意',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  children: [
                    TextSpan(
                      text: '《用户协议》',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // 打开用户协议
                        },
                    ),
                    const TextSpan(text: '和'),
                    TextSpan(
                      text: '《隐私政策》',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // 打开隐私政策
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWechatLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 微信登录图标
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF07C160).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chat_bubble,
            size: 60,
            color: Color(0xFF07C160),
          ),
        ),
        
        const SizedBox(height: 32),
        
        const Text(
          '微信一键登录',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          '使用微信账号快速登录\n无需注册，安全便捷',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
            height: 1.5,
          ),
        ),
        
        const SizedBox(height: 48),
        
        // 微信登录按钮
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _loginWithWechat,
            icon: const Icon(Icons.chat_bubble, size: 24),
            label: const Text(
              '微信登录',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF07C160),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
