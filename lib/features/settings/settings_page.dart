import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/common_widgets.dart';
import '../../data/repositories/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  static final _privacyUrl = Uri.parse(
    'https://ryushin-dev.github.io/study-collection/#privacy',
  );
  static final _termsUrl = Uri.parse(
    'https://ryushin-dev.github.io/study-collection/#terms',
  );
  static final _contactUrl = Uri.parse(
    'https://ryushin-dev.github.io/study-collection/#contact',
  );

  Future<void> _openPage(BuildContext context, Uri url) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ページを開けませんでした')));
    }
  }

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
              sectionTitle('サポート・ポリシー'),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('プライバシーポリシー'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _openPage(context, _privacyUrl),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('利用規約'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _openPage(context, _termsUrl),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.support_agent),
                title: const Text('お問い合わせ'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _openPage(context, _contactUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
