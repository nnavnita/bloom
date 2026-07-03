# Bloom

A Flutter plant journal — log care for your plants, get care reminders, track how they grow over time.

## Features

- **Plant collection** — add each plant with a photo, species, nickname, and notes. Data pulled from the [Perenual](https://perenual.com/docs/api) plant database.
- **Care log** — record watering, fertilising, repotting, and photos per plant, with an at-a-glance timeline.
- **Reminders** — local notifications for upcoming care tasks so nothing gets forgotten.
- **Explore** — browse the Perenual catalogue when picking a new plant.
- **Offline-first** — all data is stored locally with Hive; no account required.

## Stack

- Flutter (Material 3, Google Fonts)
- Riverpod for state management
- Hive for local persistence
- `flutter_local_notifications` + `timezone` for reminders
- Perenual API for the plant database
- `image_picker` + `cached_network_image` for plant photos

## Getting started

```bash
flutter pub get
flutter run
```

To enable the Perenual-backed Explore screen, drop your API key into
`lib/services/perenual_service.dart` (or set it via an env var — see comments there).

## Project layout

```
lib/
  main.dart               App entry, service init
  app.dart                MaterialApp + theming
  screens/                Home, My Plants, Add Plant, Add Log, Plant Detail, Explore, Settings
  providers/              Riverpod providers for plants, logs, settings
  services/               Storage (Hive), notifications, Perenual API client
  models/                 Plant, PlantLog
  data/                   Bundled plant database seed
  theme/                  Colours + typography
  widgets/                Reusable UI
```
