import 'package:hive/hive.dart';
import '../models/music_models.dart';

// Hive 类型适配器 ID
const int musicTrackTypeId = 1;
const int userTypeId = 2;

// 音乐轨道适配器
class MusicTrackAdapter extends TypeAdapter<MusicTrack> {
  @override
  final int typeId = musicTrackTypeId;

  @override
  MusicTrack read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MusicTrack(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String?,
      coverUrl: fields[3] as String?,
      audioUrl: fields[4] as String,
      duration: fields[5] as int,
      style: fields[6] as String?,
      prompt: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      isFavorite: fields[9] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, MusicTrack obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.coverUrl)
      ..writeByte(4)
      ..write(obj.audioUrl)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.style)
      ..writeByte(7)
      ..write(obj.prompt)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicTrackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// 本地存储服务
class LocalStorageService {
  static const String tracksBoxName = 'tracks';
  static const String settingsBoxName = 'settings';
  static const String userBoxName = 'user';

  static Future<void> initialize() async {
    // 注册适配器
    Hive.registerAdapter(MusicTrackAdapter());
    
    // 打开盒子
    await Hive.openBox<MusicTrack>(tracksBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
    await Hive.openBox<dynamic>(userBoxName);
  }

  // 获取作品盒子
  static Box<MusicTrack> get tracksBox => Hive.box<MusicTrack>(tracksBoxName);
  
  // 获取设置盒子
  static Box<dynamic> get settingsBox => Hive.box<dynamic>(settingsBoxName);
  
  // 获取用户盒子
  static Box<dynamic> get userBox => Hive.box<dynamic>(userBoxName);

  // 保存音乐作品
  static Future<void> saveTrack(MusicTrack track) async {
    await tracksBox.put(track.id, track);
  }

  // 获取所有作品
  static List<MusicTrack> getAllTracks() {
    return tracksBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // 获取收藏的作品
  static List<MusicTrack> getFavoriteTracks() {
    return tracksBox.values
        .where((track) => track.isFavorite)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // 删除作品
  static Future<void> deleteTrack(String trackId) async {
    await tracksBox.delete(trackId);
  }

  // 更新作品收藏状态
  static Future<void> toggleFavorite(String trackId) async {
    final track = tracksBox.get(trackId);
    if (track != null) {
      final updatedTrack = MusicTrack(
        id: track.id,
        title: track.title,
        artist: track.artist,
        coverUrl: track.coverUrl,
        audioUrl: track.audioUrl,
        duration: track.duration,
        style: track.style,
        prompt: track.prompt,
        createdAt: track.createdAt,
        isFavorite: !track.isFavorite,
      );
      await tracksBox.put(trackId, updatedTrack);
    }
  }

  // 清空所有作品
  static Future<void> clearAllTracks() async {
    await tracksBox.clear();
  }

  // 保存设置
  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  // 获取设置
  static T? getSetting<T>(String key, {T? defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  // 保存用户数据
  static Future<void> saveUserData(String key, dynamic value) async {
    await userBox.put(key, value);
  }

  // 获取用户数据
  static T? getUserData<T>(String key, {T? defaultValue}) {
    return userBox.get(key, defaultValue: defaultValue) as T?;
  }

  // 保存用户Token
  static Future<void> setAuthToken(String token) async {
    await userBox.put('auth_token', token);
  }

  // 获取用户Token
  static Future<String?> getAuthToken() async {
    return userBox.get('auth_token') as String?;
  }

  // 清除用户Token
  static Future<void> clearAuthToken() async {
    await userBox.delete('auth_token');
  }

  // 清除所有数据
  static Future<void> clearAll() async {
    await tracksBox.clear();
    await settingsBox.clear();
    await userBox.clear();
  }
}
