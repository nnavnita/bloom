import 'package:bloom/providers/settings_provider.dart';
import 'package:bloom/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl.text = ref.read(apiKeyProvider);
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings ⚙️')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Plant Database API'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perenual API Key (optional)',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add a free Perenual API key to search 10,000+ plants in the Explore tab. Without it, you still get 20 curated popular plants.',
                  style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyCtrl,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    hintText: 'sk-...',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureKey = !_obscureKey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(apiKeyProvider.notifier).setApiKey(_apiKeyCtrl.text.trim());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('API key saved! 🌱')),
                        );
                      }
                    },
                    child: const Text('Save API Key'),
                  ),
                ),
                if (apiKey.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '✅ API key configured',
                      style: GoogleFonts.nunito(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Open Perenual website
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Visit perenual.com to get a free API key')),
                    );
                  },
                  child: Text(
                    'Get a free key at perenual.com →',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionHeader('Notifications'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Per-plant notification settings are configured in each plant\'s edit screen.',
                  style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a plant → edit (pencil icon) → scroll to Reminders.',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionHeader('About'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _AboutRow('🌸', 'App', 'Bloom — Plant Journal'),
                _AboutRow('📦', 'Version', '1.0.0'),
                _AboutRow('🌿', 'Plant database', '20 curated plants'),
                _AboutRow('🔔', 'Notifications', 'Fully configurable per plant'),
                _AboutRow('📸', 'Photos', 'Per log entry + plant photo'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _AboutRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _AboutRow(this.emoji, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
