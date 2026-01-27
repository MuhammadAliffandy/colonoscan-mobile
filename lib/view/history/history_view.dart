import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  // State Variables
  List<dynamic> _historyList = [];
  bool _isLoading = false;      // Loading awal / refresh
  bool _isLoadingMore = false;  // Loading saat scroll bawah
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasMore = true;         // Cek apakah data masih ada di server?
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHistory(isRefresh: true);

    // Listener untuk deteksi scroll mentok bawah
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        // User sudah scroll sampai bawah -> Load Page berikutnya
        _loadMoreData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi Fetch Data Utama
  Future<void> _fetchHistory({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _historyList.clear();
        _hasMore = true;
      });
    }

    try {
      // Panggil API dengan Page saat ini
      List<dynamic> newItems = await ApiService.getHistory(page: _currentPage, limit: _limit);

      setState(() {
        if (newItems.length < _limit) {
          _hasMore = false; // Data habis, server kirim kurang dari 10
        }
        _historyList.addAll(newItems);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Fungsi Load More (Pagination)
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++; // Naikkan halaman
    });

    try {
      List<dynamic> newItems = await ApiService.getHistory(page: _currentPage, limit: _limit);
      setState(() {
        if (newItems.length < _limit) _hasMore = false;
        _historyList.addAll(newItems);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  // Fungsi Delete
  Future<void> _deleteItem(int index) async {
    final item = _historyList[index];
    final String id = item['id'];

    // Konfirmasi Dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Analysis?"),
        content: const Text("This action cannot be undone. The image and data will be removed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Hapus di Server
      bool success = await ApiService.deleteHistoryItem(id);
      
      if (success) {
        // Hapus di UI (Tanpa Refresh biar smooth)
        setState(() {
          _historyList.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item deleted.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete.")));
      }
    }
  }

  // Helper Warna & Label (Sama seperti sebelumnya)
  String _getLabel(int score) {
    switch (score) {
      case 0: return "Normal";
      case 1: return "Mild Inflammation";
      case 2: return "Moderate Inflammation";
      case 3: return "Severe Inflammation";
      default: return "Unknown";
    }
  }

  Color _getStatusColor(int score) {
    if (score == 0) return Colors.green;
    if (score == 1) return Colors.amber.shade700;
    if (score >= 2) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analysis History", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _historyList.isEmpty 
          ? const Center(child: Text("No history yet.", style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: () => _fetchHistory(isRefresh: true),
              child: ListView.builder(
                controller: _scrollController, // Pasang Controller
                padding: const EdgeInsets.all(16),
                // +1 item untuk indikator loading di paling bawah
                itemCount: _historyList.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  
                  // Jika ini item terakhir dan masih ada data -> Tampilkan Loading kecil
                  if (index == _historyList.length) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator.adaptive()));
                  }

                  final item = _historyList[index];
                  final int score = item['score'] is int ? item['score'] : int.tryParse(item['score'].toString()) ?? 0;
                  
                  // Date Parsing
                  String dateStr = item['date'].toString();
                  try {
                    // Biar formatnya lebih cantik (Optional)
                    DateTime dt = DateTime.parse(dateStr);
                    dateStr = "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
                  } catch (_) {
                    if (dateStr.length > 16) dateStr = dateStr.substring(0, 16);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        // --- 1. GAMBAR ---
                        ClipRRect(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                          child: Image.network(
                            item['image_url'],
                            width: 100, height: 100, fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => Container(width: 100, height: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        ),
                        
                        // --- 2. INFO TEXT ---
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: _getStatusColor(score).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text("MES $score", style: TextStyle(color: _getStatusColor(score), fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    Text(dateStr, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(_getLabel(score), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),

                        // --- 3. TOMBOL DELETE (TRASH) ---
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _deleteItem(index), // Panggil fungsi delete
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}