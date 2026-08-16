import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/common_widgets.dart';
import '../../data/repositories/app_state.dart';
import '../../services/monetization_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // App Store Connectで商品と審査準備が完了するまで、購入・復元UIは公開しない。
  static const _showPremiumControls = bool.fromEnvironment('ENABLE_PREMIUM_UI');
  bool _restoringPurchases = false;

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

  Future<void> _restorePurchases() async {
    if (_restoringPurchases) return;
    setState(() => _restoringPurchases = true);

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final monetization = MonetizationController.instance;
    await monetization.restorePurchases();

    if (!mounted) return;
    setState(() => _restoringPurchases = false);
    final message = monetization.premium
        ? '購入を復元しました。'
        : monetization.errorMessage ?? '復元できる購入はありませんでした。';
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final monetization = MonetizationController.instance;
    return AnimatedBuilder(
      animation: monetization,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        children: [
          pageHeader('設定', 'アプリとデータを管理します。'),
          if (_showPremiumControls) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle('プレミアム'),
                  const SizedBox(height: 6),
                  Text(
                    monetization.premium
                        ? 'プレミアム購入済みです。すべての広告が非表示になっています。'
                        : '買い切りのプレミアムで、すべての広告を非表示にできます。',
                  ),
                  const SizedBox(height: 13),
                  if (!monetization.premium)
                    FilledButton(
                      onPressed: monetization.purchasePending
                          ? null
                          : () async {
                              await monetization.buyRemoveAds();
                              if (!context.mounted ||
                                  monetization.errorMessage == null) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(monetization.errorMessage!),
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        monetization.purchasePending
                            ? '処理中…'
                            : monetization.premiumPrice == null
                            ? '広告を非表示にする'
                            : '広告を非表示にする（${monetization.premiumPrice}）',
                      ),
                    ),
                  TextButton(
                    onPressed:
                        monetization.purchasePending || _restoringPurchases
                        ? null
                        : _restorePurchases,
                    child: Text(_restoringPurchases ? '復元中…' : '購入を復元'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
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
                if (monetization.privacyOptionsRequired)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.ads_click),
                    title: const Text('広告のプライバシー設定'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: monetization.showPrivacyOptions,
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
                    if (result) await widget.state.reset();
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
      ),
    );
  }
}
