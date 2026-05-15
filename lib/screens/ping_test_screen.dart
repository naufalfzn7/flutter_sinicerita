import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/secure_storage.dart';

/// Temporary screen untuk manual testing koneksi ke backend via GET /ping.
/// Akan diganti di tahap 2.
class PingTestScreen extends StatefulWidget {
  const PingTestScreen({super.key});

  @override
  State<PingTestScreen> createState() => _PingTestScreenState();
}

class _PingTestScreenState extends State<PingTestScreen> {
  String _result = 'Belum ditest';
  bool _isLoading = false;

  Future<void> _callPing() async {
    setState(() {
      _isLoading = true;
      _result = 'Menghubungi server...';
    });

    try {
      final storage = SecureStorage();
      final apiClient = ApiClient(storage: storage);

      final response = await apiClient.dio.get(ApiEndpoints.ping);

      final success = response.data['success'] as bool?;
      final message = response.data['message'] as String?;

      debugPrint('=== PING RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('success: $success');
      debugPrint('message: $message');
      debugPrint('Full data: ${response.data}');
      debugPrint('=====================');

      if (success == true && message == 'pong') {
        setState(() {
          _result = '✅ Berhasil! Response: { success: $success, message: "$message" }';
        });
      } else {
        setState(() {
          _result = '⚠️ Response tidak sesuai: ${response.data}';
        });
      }
    } catch (e) {
      debugPrint('=== PING ERROR ===');
      debugPrint('Error: $e');
      debugPrint('==================');

      setState(() {
        _result = '❌ Gagal: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SiniCerita'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ping Test',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Test koneksi ke backend via GET /ping',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _callPing,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Panggil GET /ping'),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
