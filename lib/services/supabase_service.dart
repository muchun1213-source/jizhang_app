import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 服务：初始化客户端
/// 使用前需要先在 Supabase 控制台创建项目，获取 URL 和 anonKey
class SupabaseService {
  static const _url = 'https://rsreeuzxsxotybuuifyh.supabase.co';
  static const _anonKey = 'sb_publishable_5V9P_EBqz6F3PseNP09Hqw_i50LpGyI';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
