import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asmrapp/presentation/viewmodels/settings/cache_manager_viewmodel.dart';

class CacheManagerScreen extends StatelessWidget {
  const CacheManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CacheManagerViewModel()..loadCacheSize(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('缓存管理'),
        ),
        body: Consumer<CacheManagerViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Text(
                  viewModel.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }

            return ListView(
              children: [
                // 音频缓存
                ListTile(
                  title: const Text('音频缓存'),
                  subtitle: Text(viewModel.audioCacheSizeFormatted),
                  trailing: TextButton(
                    onPressed: viewModel.isLoading 
                      ? null 
                      : () => viewModel.clearAudioCache(),
                    child: const Text('清理'),
                  ),
                ),
                const Divider(),
                
                // 字幕缓存
                ListTile(
                  title: const Text('字幕缓存'),
                  subtitle: Text(viewModel.subtitleCacheSizeFormatted),
                  trailing: TextButton(
                    onPressed: viewModel.isLoading 
                      ? null 
                      : () => viewModel.clearSubtitleCache(),
                    child: const Text('清理'),
                  ),
                ),
                const Divider(),

                // 图片缓存
                ListTile(
                  title: const Text('图片缓存'),
                  subtitle: Text(viewModel.imageCacheSizeFormatted),
                  trailing: TextButton(
                    onPressed: viewModel.isLoading
                      ? null
                      : () => viewModel.clearImageCache(),
                    child: const Text('清理'),
                  ),
                ),
                const Divider(),

                // 总缓存大小
                ListTile(
                  title: const Text('总缓存大小'),
                  subtitle: Text(viewModel.totalCacheSizeFormatted),
                  trailing: TextButton(
                    onPressed: viewModel.isLoading 
                      ? null 
                      : () => viewModel.clearAllCache(),
                    child: const Text('清理全部'),
                  ),
                ),
                const Divider(),
                
                // 缓存说明
                const ListTile(
                  title: Text('缓存说明'),
                  subtitle: Text(
                    '缓存用于存储最近播放的音频文件、字幕文件和图片，以提高加载速度。'
                    '清理全部会同时清除所有类型的缓存数据。'
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 