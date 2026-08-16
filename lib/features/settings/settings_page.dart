import 'package:flutter/material.dart';

import '../../app/common_widgets.dart';
import '../../data/repositories/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      children: [
        pageHeader('設定', 'アプリとデータを管理します。'),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle('データと設定の初期化'),
              const SizedBox(height: 6),
              const Text('アプリの設定・手帳・記録・画像をすべて削除します。'),
              const SizedBox(height: 13),
              OutlinedButton(
                onPressed: () async {
                  final result = await confirm(
                    context,
                    title: '本当にすべて削除しますか？',
                    message: 'この操作は元に戻せません。ローカルの手帳・記録・画像がすべて削除されます。',
                  );
                  if (result) await state.reset();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('設定をすべて削除'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
