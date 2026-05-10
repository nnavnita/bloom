import 'package:bloom/models/plant.dart';
import 'package:bloom/models/plant_log.dart';
import 'package:bloom/providers/logs_provider.dart';
import 'package:bloom/providers/plants_provider.dart';
import 'package:bloom/screens/add_plant_screen.dart';
import 'package:bloom/screens/plant_detail_screen.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/theme/app_theme.dart';
import 'package:bloom/widgets/plant_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class MyPlantsScreen extends ConsumerStatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  ConsumerState<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends ConsumerState<MyPlantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPlants = ref.watch(plantsProvider);
    final indoor = ref.watch(indoorPlantsProvider);
    final outdoor = ref.watch(outdoorPlantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text('Bloom', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(text: 'All (${allPlants.length})'),
            Tab(text: '🏠 Indoor (${indoor.length})'),
            Tab(text: '☀️ Outdoor (${outdoor.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PlantGrid(plants: allPlants),
          _PlantGrid(plants: indoor),
          _PlantGrid(plants: outdoor),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPlantScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add plant'),
      ),
    );
  }
}

class _PlantGrid extends ConsumerWidget {
  final List<Plant> plants;
  const _PlantGrid({required this.plants});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🪴', style: TextStyle(fontSize: 64)).animate().scale(delay: 200.ms),
            const SizedBox(height: 16),
            Text(
              'No plants here yet!',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first plant',
              style: GoogleFonts.nunito(color: Colors.grey.shade500),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: plants.length,
      itemBuilder: (ctx, i) {
        final plant = plants[i];
        return PlantCard(
          plant: plant,
          onTap: () async {
            await Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)),
            );
            ref.read(plantsProvider.notifier).refresh();
          },
          onQuickWater: () => _quickWater(ctx, ref, plant),
        ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Future<void> _quickWater(BuildContext context, WidgetRef ref, Plant plant) async {
    final log = PlantLog(
      id: const Uuid().v4(),
      plantId: plant.id,
      date: DateTime.now(),
      health: StorageService.getLatestHealth(plant.id) ?? PlantHealth.good,
      watered: true,
    );
    await ref.read(logsProvider(plant.id).notifier).addLog(log);
    ref.read(plantsProvider.notifier).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💧 ${plant.displayName} watered!')),
      );
    }
  }
}
