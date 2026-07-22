import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../theme/theme.dart';
import 'settings_service.dart';

/// Parent-facing settings screen.
///
/// Reached through the parent gate. Changes apply live to the audio engine
/// and are persisted via [SettingsService].
class SettingsScreen extends StatelessWidget {
  final AudioService audio;
  final SettingsService settingsService;

  const SettingsScreen({
    super.key,
    required this.audio,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          'Grown-up Settings',
          style: AppTextStyles.sceneTitle.copyWith(
            color: AppColors.ink,
            fontSize: 28,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListenableBuilder(
            listenable: settingsService,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMusicTile(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMusicTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: AppColors.mehndi,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Background music',
                style: AppTextStyles.cardLabel.copyWith(
                  color: AppColors.ink,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.volume_mute,
                color: AppColors.ink.withValues(alpha: 0.5),
                size: 20,
              ),
              Expanded(
                child: Slider(
                  value: settingsService.musicVolume,
                  onChanged: (value) {
                    audio.musicVolume = value;
                    settingsService.musicVolume = value;
                  },
                  activeColor: AppColors.mehndi,
                  inactiveColor: AppColors.ink.withValues(alpha: 0.15),
                ),
              ),
              Icon(
                Icons.volume_up,
                color: AppColors.ink.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(settingsService.musicVolume * 100).round()}%',
              style: AppTextStyles.wordCardGloss.copyWith(
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
