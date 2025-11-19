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

### Pola Desain yang Diterapkan

#### 1. **Provider Pattern** (State Management)

Menggunakan Provider dengan ChangeNotifier untuk state management yang clean:

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

  // Login method - mengupdate state dan notify listeners
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

        // Simpan ke local storage untuk persistent login
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

#### 2. **Service Layer Pattern** (Business Logic & API)

Services menangani API calls dan business logic yang terpisah dari UI:

```dart
// services/api_service.dart
class ApiService {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001'); // Android emulator default

  // Helper method untuk GET request dengan auth header
  static Future<Response> get(String endpoint, {String? token}) {
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30)); // 30 second timeout
  }

  // Helper method untuk POST dengan error handling
  static Future<Response> post(String endpoint, Map<String, dynamic> body,
      {String? token}) {
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

// services/storage_service.dart - Local storage untuk persistent data
class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // Simpan token ke local storage untuk automatic login
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

#### 3. **Model/DTO Pattern** (Type Safety)

```dart
// models/task.dart - Type-safe data handling dari API
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

  // Factory constructor untuk parsing dari JSON API response
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

  // Convert ke JSON untuk API calls
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

#### 4. **Consumer Pattern** (Widget Building)

Consumer widget untuk subscribe ke state changes hanya ketika diperlukan:

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

# Output harus menunjukkan: ✓ Flutter, ✓ Android toolchain, ✓ Xcode (untuk iOS)
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

Buat atau update file `lib/config/api_config.dart`:

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

# Run dengan debug prints verbose
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

# Run dengan hot reload enabled
flutter run
```

### Hot Reload & Hot Restart

```bash
# Saat app running, di terminal tekan:
r     # Hot reload - update kode tanpa state reset
R     # Hot restart - restart app dengan state reset
q     # Quit app
```

---

## 📦 Build APK & IPA

### Build Android APK

```bash
# Build release APK yang optimal untuk production
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Build app bundle untuk Google Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build iOS IPA

```bash
# Build iOS app
flutter build ios --release

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
│   ├── models/                        # Data models & DTOs
│   │   ├── user_model.dart
│   │   └── task_model.dart
│   ├── providers/                     # State management (Provider)
│   │   ├── auth_provider.dart         # Authentication state
│   │   └── task_provider.dart         # Task management state
│   ├── screens/                       # UI Screens
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   └── task_detail_screen.dart
│   ├── services/                      # Business logic & API
│   │   ├── api_service.dart           # HTTP client
│   │   ├── auth_service.dart
│   │   ├── task_service.dart
│   │   └── storage_service.dart       # Local storage
│   └── config/
│       └── api_config.dart            # API configuration
│
├── android/                           # Android native code
│   ├── app/build.gradle.kts
│   └── src/main/AndroidManifest.xml
│
├── ios/                               # iOS native code
│   ├── Runner/
│   └── Runner.xcodeproj/
│
├── pubspec.yaml                       # Dependencies & project config
├── pubspec.lock                       # Lock file
├── analysis_options.yaml              # Lint rules
└── README.md                          # Dokumentasi (file ini)
```

---

## ✨ Fitur Utama

### 1. Autentikasi User

- Register & login dengan validasi
- Persistent login dengan token storage
- Logout dengan clear session

### 2. Manajemen Tugas (CRUD)

- Buat, baca, perbarui, hapus tugas
- Support untuk title, description, priority, due date
- Real-time sync dengan backend

### 3. Filtering & Search

- Filter berdasarkan status (All, To-Do, In-Progress, Done)
- Filter berdasarkan prioritas (All, Low, Medium, High)
- Search task berdasarkan title/description

### 4. UI/UX Features

- Material Design 3 compliance
- Responsive layout untuk berbagai screen sizes
- Loading indicators & error handling
- Date picker untuk due date selection

---

## 🐛 Troubleshooting

| Masalah                      | Solusi                                          |
| ---------------------------- | ----------------------------------------------- |
| `flutter: command not found` | Tambah Flutter bin ke PATH environment variable |
| Android emulator error       | Buka Android Studio → Virtual Device Manager    |
| iOS build error              | Jalankan `cd ios && pod install && cd ..`       |
| "No connected devices"       | Hubungkan physical device atau buka emulator    |
| API connection refused       | Pastikan backend running, check API_BASE_URL    |
| Hot reload tidak berjalan    | Coba hot restart dengan tekan 'R'               |

---

## 🚀 Deployment

### Android Play Store

- Build app bundle: `flutter build appbundle --release`
- Upload ke Google Play Console

### iOS App Store

- Build IPA: `flutter build ipa --release`
- Upload via Xcode atau Apple Transporter

### Firebase Distribution (Beta)

```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --release-notes "Beta v1.0"
```

---

## 📱 Download Aplikasi

### Android

- **Google Play Store**: [Link ke app di Play Store]
- **Direct APK**: [Link download APK v1.0.0]

### iOS

- **App Store**: [Link ke app di App Store]
- **TestFlight**: [Link TestFlight beta]

### Minimum Requirements

- **Android**: 6.0 (API 21)+, 50MB storage
- **iOS**: 12.0+, 80MB storage

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Provider Package](https://pub.dev/packages/provider)
- [Material Design 3](https://material.io/design)

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
