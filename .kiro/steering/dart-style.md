---
inclusion: fileMatch
fileMatchPattern: "**/*.dart"
---

# Dart/Flutter Code Style

## Import Order

1. `dart:` libraries
2. `package:flutter/` 
3. `package:` third-party
4. Relative imports (project files)

Pisahkan tiap grup dengan blank line.

## Class Structure Order

1. Static/const fields
2. Final fields
3. Mutable fields
4. Constructor
5. Factory constructors
6. Getters/setters
7. Public methods
8. Private methods

## Provider Pattern

```dart
class XxxProvider extends ChangeNotifier {
  // State fields (private)
  bool _isLoading = false;
  String? _errorMessage;

  // Getters (public)
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Methods — always:
  // 1. Set loading state
  // 2. Clear previous error
  // 3. Try-catch with DioException
  // 4. Convert to AppException
  // 5. notifyListeners() at end
  Future<bool> doSomething() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // API call
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
```

## Widget Best Practices

- Gunakan `const` constructor di mana mungkin
- Extract widget ke class terpisah jika > 50 baris
- Gunakan `context.read<T>()` untuk aksi (method call)
- Gunakan `context.watch<T>()` untuk rebuild saat state berubah
- Jangan panggil `context.watch` di dalam callback/async

## Null Safety

- Prefer non-nullable types
- Gunakan `required` untuk parameter wajib
- Gunakan `late` hanya jika yakin akan di-init sebelum dipakai
- Prefer `??` dan `?.` daripada explicit null check

## Error Handling di Screen

```dart
// Pattern standar untuk button onPressed
Future<void> _onSubmit() async {
  if (!_formKey.currentState!.validate()) return;
  
  final success = await context.read<AuthProvider>().login(...);
  if (!mounted) return;
  
  if (success) {
    context.go('/main');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.read<AuthProvider>().errorMessage ?? 'Error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## Naming Conventions

| Jenis | Convention | Contoh |
|-------|-----------|--------|
| File | snake_case | `auth_provider.dart` |
| Class | PascalCase | `AuthProvider` |
| Variable | camelCase | `isLoading` |
| Constant | camelCase | `baseUrl` |
| Private | _prefix | `_isLoading` |
| Enum value | camelCase | `AuthStatus.authenticated` |
