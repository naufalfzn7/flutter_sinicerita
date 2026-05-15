/// Immutable result dari session completion API.
///
/// Digunakan untuk passing data dari SessionProvider ke UI
/// setelah sesi berhasil di-complete. Bukan model backend —
/// di-construct manual di provider dari parsed API response.
class CompletionResult {
  final int scoreDelta;
  final int newPoints;
  final int previousPoints;
  final String summary;

  const CompletionResult({
    required this.scoreDelta,
    required this.newPoints,
    required this.previousPoints,
    required this.summary,
  });
}
