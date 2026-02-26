import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'blocs/music_generation/music_generation_bloc.dart';
import 'blocs/chat/chat_bloc.dart';
import 'providers/theme_provider.dart';
import 'providers/membership_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/api_service.dart';
import 'services/music_player_service.dart';
import 'services/local_storage_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive
  await Hive.initFlutter();
  await LocalStorageService.initialize();
  
  // 设置首选方向
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const HaoHaoApp());
}

class HaoHaoApp extends StatelessWidget {
  const HaoHaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MembershipProvider()),
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => MusicPlayerService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ChatBloc()),
          BlocProvider(create: (context) => MusicGenerationBloc()),
        ],
        child: Consumer2<ThemeProvider, MembershipProvider>(
          builder: (context, themeProvider, membershipProvider, child) {
            // 初始化会员系统
            if (!membershipProvider.isLoading && membershipProvider.user == null) {
              membershipProvider.initialize();
            }
            
            return MaterialApp(
              title: '皓皓同学 - AI音乐创作',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}