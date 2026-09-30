import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

final _adminOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ref.read(apiClientProvider).get<dynamic>('/admin/overview');
  final body = response.data;
  if (body is Map && body['data'] is Map) {
    return Map<String, dynamic>.from(body['data'] as Map);
  }
  throw StateError('Invalid administrator overview response');
});

/// Operational dashboard. Data is loaded only from the server-side admin API.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(_adminOverviewProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdminError(onRetry: () => ref.invalidate(_adminOverviewProvider)),
        data: (data) => _AdminOverview(
          data: data,
          onRefresh: () async {
            ref.invalidate(_adminOverviewProvider);
            await ref.read(_adminOverviewProvider.future);
          },
        ),
      ),
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({required this.data, required this.onRefresh});
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final metrics = data['metrics'] is Map ? Map<String, dynamic>.from(data['metrics'] as Map) : const <String, dynamic>{};
    final services = data['services'] is Map ? Map<String, dynamic>.from(data['services'] as Map) : const <String, dynamic>{};
    final cards = <_Metric>[
      _Metric('Requests', _value(metrics, 'totalRequests')),
      _Metric('Errors', _value(metrics, 'totalErrors')),
      _Metric('AI requests', _value(metrics, 'aiRequests')),
      _Metric('TTS requests', _value(metrics, 'ttsRequests')),
    ];
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('System overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Live operational data is available only to authorized administrators.'),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
            childAspectRatio: 1.65,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cards
                .map(
                  (item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label),
                          const Spacer(),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text('Service configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(child: Column(children: [
            _ServiceRow(label: 'Database configured', value: services['databaseConfigured'] == true ? 'Yes' : 'No'),
            _ServiceRow(label: 'AI provider', value: '${services['aiProvider'] ?? 'Unavailable'}'),
            _ServiceRow(label: 'TTS provider', value: '${services['ttsProvider'] ?? 'Unavailable'}'),
          ])),
          const SizedBox(height: 24),
          const Text('Content management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Lesson, vocabulary, and activity editing will appear here after the server-backed content catalog migration is enabled.'))),
        ],
      ),
    );
  }

  String _value(Map<String, dynamic> map, String key) => '${map[key] ?? 0}';
}

class _Metric { const _Metric(this.label, this.value); final String label; final String value; }
class _ServiceRow extends StatelessWidget { const _ServiceRow({required this.label, required this.value}); final String label; final String value; @override Widget build(BuildContext context) => ListTile(title: Text(label), trailing: Text(value)); }
class _AdminError extends StatelessWidget { const _AdminError({required this.onRetry}); final VoidCallback onRetry; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Unable to load the administrator dashboard. Sign in with an administrator account and try again.', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('Retry'))]))); }
