import 'package:bloom/data/plant_database.dart';
import 'package:bloom/models/plant.dart';
import 'package:bloom/screens/add_plant_screen.dart';
import 'package:bloom/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  List<LocalPlant> _results = kPlantDatabase;
  String _filterType = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    final ql = q.toLowerCase();
    setState(() {
      _results = kPlantDatabase.where((p) {
        final matchQuery = ql.isEmpty ||
            p.name.toLowerCase().contains(ql) ||
            p.species.toLowerCase().contains(ql);
        final matchType = _filterType == 'all' ||
            (_filterType == 'indoor' && p.type == PlantType.indoor) ||
            (_filterType == 'outdoor' && p.type == PlantType.outdoor);
        return matchQuery && matchType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Plants 🌍'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                hintText: 'Search plants...',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(label: '🌿 All', value: 'all', selected: _filterType, onTap: (v) { setState(() => _filterType = v); _search(_searchCtrl.text); }),
                const SizedBox(width: 8),
                _FilterChip(label: '🏠 Indoor', value: 'indoor', selected: _filterType, onTap: (v) { setState(() => _filterType = v); _search(_searchCtrl.text); }),
                const SizedBox(width: 8),
                _FilterChip(label: '☀️ Outdoor', value: 'outdoor', selected: _filterType, onTap: (v) { setState(() => _filterType = v); _search(_searchCtrl.text); }),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No plants found', style: Theme.of(context).textTheme.titleMedium),
                        Text('Try a different search', style: GoogleFonts.nunito(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: _results.length,
                    itemBuilder: (ctx, i) => _PlantExploreCard(
                      plant: _results[i],
                      onAdd: () => _addToGarden(ctx, _results[i]),
                    ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.05),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToGarden(BuildContext context, LocalPlant lp) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlantScreen(
          existing: Plant(
            id: const Uuid().v4(),
            name: lp.name,
            type: lp.type,
            species: lp.species,
            dateAdded: DateTime.now(),
            careTips: lp.careTips,
            wateringFrequency: lp.wateringFrequency,
            sunlight: lp.sunlight,
            difficulty: lp.difficulty,
          ),
        ),
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🌱 ${lp.name} added to your garden!')),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _PlantExploreCard extends StatefulWidget {
  final LocalPlant plant;
  final VoidCallback onAdd;

  const _PlantExploreCard({required this.plant, required this.onAdd});

  @override
  State<_PlantExploreCard> createState() => _PlantExploreCardState();
}

class _PlantExploreCardState extends State<_PlantExploreCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.plant.type == PlantType.indoor
                          ? AppColors.primary.withOpacity(0.08)
                          : Colors.amber.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(widget.plant.emoji, style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plant.name,
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        Text(
                          widget.plant.species,
                          style: GoogleFonts.nunito(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            _MiniChip(widget.plant.type == PlantType.indoor ? '🏠 Indoor' : '☀️ Outdoor'),
                            _MiniChip('⭐ ${widget.plant.difficulty}'),
                            _MiniChip('💧 ${widget.plant.wateringFrequency.split('–').first.trim()}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.plant.description, style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                  const SizedBox(height: 10),
                  Text('Care tips:', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  ...widget.plant.careTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌱 ', style: TextStyle(fontSize: 12)),
                        Expanded(child: Text(tip, style: GoogleFonts.nunito(fontSize: 13, height: 1.4))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add to My Garden'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  const _MiniChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
}
