import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/episode_repository_impl.dart';
import '../../data/services/storage_service.dart';

final episodeGameDataProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, episodeId) async {
    final repository = ref.watch(episodeRepositoryProvider);
    return await repository.loadEpisodeGameData(episodeId);
  },
);

class GameScreen extends ConsumerWidget {
  final String episodeId;
  
  const GameScreen({
    super.key,
    required this.episodeId,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameDataAsync = ref.watch(episodeGameDataProvider(episodeId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playing Episode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: gameDataAsync.when(
        data: (gameData) => _GameContent(
          episodeId: episodeId,
          gameData: gameData,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load episode: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameContent extends ConsumerStatefulWidget {
  final String episodeId;
  final Map<String, dynamic> gameData;
  
  const _GameContent({
    required this.episodeId,
    required this.gameData,
  });
  
  @override
  ConsumerState<_GameContent> createState() => _GameContentState();
}

class _GameContentState extends ConsumerState<_GameContent> {
  int _currentStep = 0;
  
  @override
  Widget build(BuildContext context) {
    // This is a simplified game content view
    // You would implement your actual game logic here
    
    // final title = widget.gameData['title'] as String? ?? 'Investigation';
    final story = widget.gameData['story'] as List<dynamic>? ?? [];
    
    if (story.isEmpty) {
      return const Center(
        child: Text('No story content available'),
      );
    }
    
    final currentScene = story[_currentStep] as Map<String, dynamic>;
    final sceneText = currentScene['text'] as String? ?? '';
    final sceneImage = currentScene['image'] as String?;
    
    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_currentStep + 1) / story.length,
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scene image (loaded from local files)
                if (sceneImage != null)
                  _buildLocalImage(sceneImage),
                
                const SizedBox(height: 16),
                
                // Scene text
                Text(
                  sceneText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        
        // Navigation
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      onPressed: () {
                        setState(() => _currentStep--);
                      },
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _currentStep < story.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                    ),
                    label: Text(
                      _currentStep < story.length - 1 ? 'Next' : 'Finish',
                    ),
                    onPressed: () {
                      if (_currentStep < story.length - 1) {
                        setState(() => _currentStep++);
                      } else {
                        _showCompletionDialog();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLocalImage(String imageName) {
    return FutureBuilder<File>(
      future: _getImageFile(imageName),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              // Memory optimization: decode at display size
              cacheWidth: (MediaQuery.of(context).size.width * 
                  MediaQuery.of(context).devicePixelRatio).toInt(),
            ),
          );
        }
        
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.image, size: 48, color: Colors.grey),
          ),
        );
      },
    );
  }
  
  Future<File> _getImageFile(String imageName) async {
    final storageService = ref.read(storageServiceProvider);
    final installed = await storageService.loadInstalledEpisodes();
    final episode = installed.findById(widget.episodeId);
    
    if (episode == null) {
      throw Exception('Episode not found');
    }
    
    return storageService.getEpisodeImage(episode.localPath, imageName);
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Episode Complete! 🎉'),
        content: const Text(
          'Congratulations! You have completed this investigation episode.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to episode list
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}