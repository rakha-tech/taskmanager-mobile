# Sarastya Task Manager - Mobile App

Aplikasi manajemen tugas mobile yang dibangun dengan Flutter untuk platform Android dan iOS. Menyediakan pengalaman pengguna yang seamless dalam mengelola tugas-tugas harian dengan antarmuka yang intuitif dan responsif.

## 📋 Daftar Isi

- [Deskripsi Proyek](#-deskripsi-proyek)
- [Teknologi Utama](#-teknologi-utama)
- [Arsitektur & Pola Desain](#-arsitektur--pola-desain)
- [Setup & Instalasi](#-setup--instalasi)
- [Menjalankan Aplikasi](#-menjalankan-aplikasi)
- [Build APK & IPA](#-build-apk--ipa)
- [Struktur Proyek](#-struktur-proyek)
- [Fitur Utama](#-fitur-utama)
- [Deployment](#-deployment)
- [Download Aplikasi](#-download-aplikasi)

---

## 🎯 Deskripsi Proyek

Sarastya Task Manager Mobile adalah aplikasi cross-platform untuk manajemen tugas dengan fitur:

- **Autentikasi Multi-Platform**: Register & login dengan sinkronisasi ke backend
- **Manajemen Tugas Offline-First**: Bekerja offline dengan sync otomatis
- **Push Notifications**: Notifikasi reminder untuk deadline tugas
- **Material Design 3**: UI modern sesuai Material Design 3 guidelines
- **State Management**: Menggunakan Provider untuk state management yang efisien
- **Local Storage**: Caching data lokal dengan SharedPreferences
- **Cross-Platform**: Build untuk Android dan iOS dari satu codebase

---

## 🛠️ Teknologi Utama

| Teknologi                | Versi  | Kegunaan                               |
| ------------------------ | ------ | -------------------------------------- |
| **Flutter**              | 3.9.2+ | Cross-platform mobile framework        |
| **Dart**                 | 3.9.2+ | Programming language                   |
| **Provider**             | 6.1.2  | State management & ChangeNotifier      |
| **HTTP**                 | 1.6.0  | HTTP client untuk API calls            |
| **SharedPreferences**    | 2.3.2  | Local data persistence                 |
| **Intl**                 | 0.20.2 | Internationalization & date formatting |
| **Form Field Validator** | 1.1.0  | Form validation utilities              |
| **Material Design 3**    | Latest | UI components & theming                |

---

## 🏗️ Arsitektur & Pola Desain

### Arsitektur Umum

```
┌─────────────────────────────────────┐
│    Flutter Mobile Application       │
├─────────────────────────────────────┤
│   Presentation Layer (Screens)      │
│   ├─ LoginScreen                    │
│   ├─ DashboardScreen                │
│   └─ TaskDetailScreen               │
├─────────────────────────────────────┤
│   State Management (Provider)       │
│   ├─ AuthProvider                   │
│   └─ TaskProvider                   │
├─────────────────────────────────────┤
│   Services & API Layer              │
│   ├─ ApiService                     │
│   ├─ StorageService                 │
│   └─ AuthService                    │
├─────────────────────────────────────┤
│   Models & Data Layer               │
│   ├─ User Model                     │
│   └─ Task Model                     │
├─────────────────────────────────────┤
│   Local Storage (SharedPreferences) │
└─────────────────────────────────────┘
         │
         ▼
    Backend API
```

### Pola Desain yang Diterapkan

#### 1. **Provider Pattern** (State Management)

Provider adalah state management solution yang menggunakan ChangeNotifier untuk meng-manage state:

```dart
// providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;

  // Login method - mengupdate state
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners(); // Notify UI untuk update

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);

        // Simpan ke local storage untuk persistence
        await StorageService.saveToken(_token!);
        await StorageService.saveUser(_user!);
      } else {
        throw Exception('Login failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify setelah operasi selesai
    }
  }
}
```

#### 2. **MultiProvider Pattern** (Multiple State Management)

Menggunakan MultiProvider untuk meng-inject multiple providers ke aplikasi:

```dart
// main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        // AuthProvider harus di-initialize lebih dulu
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // TaskProvider depend pada AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, authProvider, taskProvider) {
            taskProvider?.setToken(authProvider.token);
            return taskProvider!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

#### 3. **Service Layer Pattern** (Business Logic & API)

Services menangani API calls dan business logic yang terpisah dari UI:

```dart
// services/api_service.dart
class ApiService {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001'); // Android emulator default

  static Future<Response> get(String endpoint, {String? token}) {
    // Helper method untuk GET request dengan auth header
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30)); // 30 second timeout
  }

  static Future<Response> post(String endpoint, Map<String, dynamic> body,
      {String? token}) {
    // Helper method untuk POST dengan error handling
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
  }
}

// services/storage_service.dart
class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // Simpan token ke local storage untuk persistent login
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Retrieve token dari storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Clear storage saat logout
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

#### 4. **Model/DTO Pattern** (Type Safety)

Models untuk type-safe data handling dari API:

```dart
// models/user.dart
class User {
  final int id;
  final String email;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });

  // Factory constructor untuk parsing dari JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
    );
  }

  // Convert ke JSON untuk API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}

// models/task.dart
class Task {
  final int id;
  final String title;
  final String description;
  final String status; // 'ToDo', 'InProgress', 'Done'
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime? dueDate;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

#### 5. **Consumer Pattern** (Widget Building)

Consumer widget untuk subscribe ke state changes:

```dart
// Komentar: Consumer rebuild hanya widget tertentu saat state berubah
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    if (authProvider.isLoading) {
      return const CircularProgressIndicator();
    }

    if (authProvider.user == null) {
      return const LoginScreen();
    }

    return const DashboardScreen();
  },
)
```

---

## 📦 Setup & Instalasi

### Prasyarat

Pastikan Anda telah menginstal:

- **Flutter SDK** (3.9.2 atau lebih tinggi)
  - Download dari https://flutter.dev/docs/get-started/install
- **Dart SDK** (sudah included dalam Flutter)
- **Android Studio** atau **Xcode** untuk emulator/device testing
- **Git** - Version control

### Verifikasi Instalasi

```bash
# Check Flutter version
flutter --version

# Check Dart version
dart --version

# Check setup lengkap
flutter doctor

# Output harus menunjukkan:
# ✓ Flutter
# ✓ Android toolchain
# ✓ Xcode (untuk iOS)
# ✓ VS Code (atau IDE lainnya)
```

### Instalasi Mobile App

1. **Clone repository**

```bash
git clone https://github.com/rakha-tech/taskmanager-mobile.git
cd taskmanager_mobile
```

2. **Get dependencies**

```bash
# Download semua pub packages
flutter pub get

# Atau update ke versi terbaru
flutter pub upgrade
```

3. **Setup environment variables**

Buat file `lib/config/api_config.dart`:

```dart
// lib/config/api_config.dart
class ApiConfig {
  // API Base URL - sesuaikan dengan backend URL
  static const String baseUrl = 'http://10.0.2.2:3001'; // Android emulator
  // static const String baseUrl = 'http://localhost:3001'; // iOS simulator
  // static const String baseUrl = 'https://api.sarastya.com'; // Production

  static const Duration timeout = Duration(seconds: 30);
  static const int retryCount = 3;
}
```

4. **Generate build files** (Android/iOS)

```bash
# Generate Android/iOS native files
flutter pub get

# (Optional) Untuk iOS
cd ios && pod install && cd ..
```

---

## 🚀 Menjalankan Aplikasi

### Mode Development

#### Android

```bash
# List available devices/emulators
flutter devices

# Run di Android device/emulator
flutter run

# Atau run di specific device
flutter run -d emulator-5554

# Run dengan debug prints
flutter run -v

# Run di release mode (faster)
flutter run --release
```

#### iOS

```bash
# Run di iOS simulator
flutter run -d "iPhone 14"

# List iOS simulators
xcrun simctl list devices

# Run dengan hot reload
flutter run

# Hot reload during development
# Press 'r' untuk hot reload
# Press 'R' untuk restart
```

### Hot Reload & Hot Restart

```bash
# Saat app running, di terminal tekan:
r     # Hot reload - update kode tanpa state reset
R     # Hot restart - restart app dengan state reset
q     # Quit app
```

### Mode Profiling (Performance)

```bash
# Run dengan timeline profiler
flutter run --profile

# Run dengan memory profiling
flutter run --profile --track-widget-creation
```

---

## 📦 Build APK & IPA

### Build Android APK

#### APK Debug

```bash
# Build debug APK untuk testing
flutter build apk --debug

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### APK Release

```bash
# Build release APK yang optimal untuk production
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (untuk Google Play Store)

```bash
# Build app bundle untuk upload ke Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build iOS IPA

#### Prerequisites

```bash
# Pastikan Xcode installed
xcode-select --install

# Accept Xcode license
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

#### Build IPA

```bash
# Build iOS app
flutter build ios --release

# Output: build/ios/iphoneos/Runner.app

# Build IPA untuk TestFlight/App Store
flutter build ipa --release

# Output: build/ios/ipa/taskmanager_mobile.ipa
```

---

## 📁 Struktur Proyek

```
taskmanager_mobile/
├── lib/
│   ├── main.dart                      # Entry point aplikasi
│   │
│   ├── models/                        # Data models & DTOs
│   │   ├── user_model.dart
│   │   └── task_model.dart
│   │
│   ├── providers/                     # State management (Provider)
│   │   ├── auth_provider.dart         # Authentication state
│   │   └── task_provider.dart         # Task management state
│   │
│   ├── screens/                       # UI Screens
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── task_detail_screen.dart
│   │   └── settings_screen.dart
│   │
│   ├── services/                      # Business logic & API
│   │   ├── api_service.dart           # HTTP client & API calls
│   │   ├── auth_service.dart
│   │   ├── task_service.dart
│   │   └── storage_service.dart       # Local storage dengan SharedPreferences
│   │
│   ├── widgets/                       # Reusable widgets
│   │   ├── task_card.dart
│   │   ├── task_dialog.dart
│   │   ├── filter_widget.dart
│   │   └── common_widgets.dart
│   │
│   └── config/
│       └── api_config.dart            # API configuration
│
├── android/                           # Android native code
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/main/AndroidManifest.xml
│   ├── gradle.properties
│   └── settings.gradle.kts
│
├── ios/                               # iOS native code
│   ├── Runner/
│   ├── Runner.xcodeproj/
│   └── Runner.xcworkspace/
│
├── web/                               # Web deployment files
│   └── index.html
│
├── pubspec.yaml                       # Dependencies & project config
├── pubspec.lock                       # Lock file untuk reproducible builds
├── analysis_options.yaml              # Lint rules configuration
├── devtools_options.yaml              # DevTools configuration
└── README.md                          # Dokumentasi
```

### Penjelasan Key Files

#### main.dart - Entry Point

```dart
// Komentar: Entry point aplikasi - setup providers dan theme

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Auth provider harus inisialisasi pertama kali
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Task provider menggunakan token dari auth
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, authProvider, taskProvider) {
            taskProvider?.setToken(authProvider.token);
            return taskProvider!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarastya Task Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      // Komentar: Consumer mendengarkan perubahan AuthProvider
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Navigate berdasarkan authentication state
          return authProvider.user != null
              ? const DashboardScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
```

#### pubspec.yaml - Dependencies

```yaml
# Komentar: Define semua dependencies dan assets

name: taskmanager_mobile

dependencies:
  flutter:
    sdk: flutter

  # State Management - Provider pattern untuk state management yang clean
  provider: ^6.1.2

  # HTTP Client - untuk API calls ke backend
  http: ^1.6.0

  # Local Storage - persistent storage untuk authentication tokens & data
  shared_preferences: ^2.3.2

  # Validation - untuk form validation yang reusable
  form_field_validator: ^1.1.0

  # Internationalization - untuk date formatting dan localization
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  # assets:
  #   - assets/images/
  #   - assets/icons/
```

---

## ✨ Fitur Utama

### 1. Autentikasi User

- **Register**: Buat akun baru dengan validasi email & password
- **Login**: Masuk dengan kredensial yang terdaftar
- **Persistent Login**: Token disimpan lokal untuk automatic login
- **Logout**: Clear session dan local storage

```dart
// Contoh: Login flow dengan Provider
final authProvider = Provider.of<AuthProvider>(context, listen: false);
await authProvider.login(email, password);

// Jika login berhasil, app automatically navigate ke Dashboard
```

### 2. Manajemen Tugas (CRUD)

- **Create Task**: Tambah tugas baru dengan title, description, priority, due date
- **Read Tasks**: Tampilkan daftar tugas dalam list atau card view
- **Update Task**: Edit tugas yang sudah ada
- **Delete Task**: Hapus tugas dengan konfirmasi

### 3. Filtering & Search

- **Status Filter**: Filter berdasarkan status (All, To-Do, In-Progress, Done)
- **Priority Filter**: Filter berdasarkan prioritas (All, Low, Medium, High)
- **Search**: Search task berdasarkan title/description

### 4. Offline Support

- **Local Caching**: Tugas disimpan lokal untuk akses offline
- **Auto Sync**: Saat online, data otomatis sync dengan server
- **Conflict Resolution**: Handling konflik saat sync

### 5. UI/UX Features

- **Material Design 3**: Mengikuti Material Design 3 guidelines
- **Responsive Layout**: Adaptif untuk berbagai ukuran screen
- **Loading States**: Indikator loading saat fetch data
- **Error Handling**: Pesan error yang user-friendly
- **Date Picker**: Untuk memilih due date task

---

## 🐛 Troubleshooting

| Masalah                         | Solusi                                                         |
| ------------------------------- | -------------------------------------------------------------- |
| `flutter: command not found`    | Tambah Flutter bin ke PATH environment variable                |
| Android emulator error          | Buka Android Studio → Virtual Device Manager → create emulator |
| iOS build error                 | Jalankan `cd ios && pod install && cd ..`                      |
| "No connected devices"          | Hubungkan physical device atau buka emulator                   |
| API connection refused          | Pastikan backend running, check API_BASE_URL di config         |
| Hot reload tidak berjalan       | Coba hot restart dengan tekan 'R' di terminal                  |
| Build error "permission denied" | Jalankan `chmod +x gradlew` di directory android               |

---

## 🚀 Deployment

### Android Play Store

1. **Setup Google Play Developer Account**

   - Daftar di https://play.google.com/console
   - Bayar one-time registration fee ($25)

2. **Setup Signing Key**

```bash
# Generate signing key
keytool -genkey -v -keystore ~/key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias taskmanager
```

3. **Configure signing di android/app/build.gradle.kts**

```kotlin
signingConfigs {
  release {
    keyAlias = "taskmanager"
    keyPassword = "your_password"
    storeFile = file("/path/to/key.jks")
    storePassword = "your_password"
  }
}
```

4. **Build & Upload**

```bash
# Build app bundle
flutter build appbundle --release

# Upload ke Play Store Console
# build/app/outputs/bundle/release/app-release.aab
```

### iOS App Store

1. **Setup Apple Developer Account**

   - Daftar di https://developer.apple.com/programs/
   - Bayar annual subscription ($99)

2. **Setup Certificates & Provisioning Profiles**

   - Generate di Apple Developer Console
   - Download ke local machine

3. **Build IPA**

```bash
flutter build ipa --release
```

4. **Upload via TestFlight/App Store**
   - Gunakan Xcode atau transporter
   - Submit untuk review

### Firebase Distribution (Beta Testing)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Build APK
flutter build apk --release

# Distribute via Firebase
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --release-notes "Beta release v1.0" \
  --testers-file testers.txt
```

---

## 📱 Download Aplikasi

### Android

- **Google Play Store**: [Link ke app di Play Store]
- **Direct APK Download**: [Link download APK v1.0.0]
- **GitHub Releases**: https://github.com/rakha-tech/taskmanager-mobile/releases

### iOS

- **App Store**: [Link ke app di App Store]
- **TestFlight**: [Link TestFlight beta]

### Minimum Requirements

**Android**:

- Android 6.0 (API level 21) atau lebih tinggi
- 50MB storage space

**iOS**:

- iOS 12.0 atau lebih tinggi
- 80MB storage space

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Provider State Management](https://pub.dev/packages/provider)
- [Material Design 3](https://material.io/design)
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)

---

## 🔗 Useful Links

- [Flutter DevTools Guide](https://flutter.dev/docs/development/tools/devtools)
- [Flutter Performance Profiling](https://flutter.dev/docs/testing/profiling)
- [Firebase Integration Guide](https://firebase.flutter.dev/)
- [Push Notifications Setup](https://firebase.flutter.dev/docs/messaging/overview/)

---

## 📄 License

Project ini dilisensikan di bawah MIT License.

---

## 👥 Tim Pengembang

- **Rakha Tech** - Lead Mobile Developer

---

## 📞 Kontak & Support

- Email: mrakha.tech@gmail.com
- GitHub Issues: https://github.com/rakha-tech/taskmanager-mobile/issues

---

**Last Updated**: November 19, 2025

Untuk pertanyaan atau kontribusi, silakan buka issue atau pull request di repository ini.
