import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// सीखो — pick a scene to explore words in.
class ScenePickerScreen extends StatelessWidget {
  const ScenePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: ToddlerBackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        automaticallyImplyLeading: false,
        leadingWidth: 72,
      ),
      body: Stack(children: [
        const Positioned.fill(child: GameBackdrop(color: AppColors.peacock)),
        Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DoorwayCard(
              sceneId: 'house',
              titleHi: 'घर',
              titleTranslit: 'Ghar',
              color: AppColors.marigold,
              deepColor: AppColors.marigoldDeep,
              width: 150,
              height: 176,
              onTap: () => Navigator.of(context).pushNamed('/scene/house'),
            ),
            const SizedBox(width: 24),
            DoorwayCard(
              sceneId: 'farm',
              titleHi: 'बगीचा',
              titleTranslit: 'Bageecha',
              color: AppColors.mehndi,
              deepColor: AppColors.mehndiDeep,
              width: 150,
              height: 176,
              onTap: () => Navigator.of(context).pushNamed('/scene/farm'),
            ),
            const SizedBox(width: 24),
            DoorwayCard(
              sceneId: 'family',
              titleHi: 'परिवार',
              titleTranslit: 'Parivaar',
              color: AppColors.kumkum,
              deepColor: AppColors.kumkumDeep,
              width: 150,
              height: 176,
              onTap: () => Navigator.of(context).pushNamed('/scene/family'),
            ),
          ],
        ),
      ),
      ]),
    );
  }
}
