import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api.dart'; 

// ==========================================
// 1. HALAMAN LIST SEMUA USER (AdminUserListView)
// ==========================================
class AdminUserListView extends StatefulWidget {
  const AdminUserListView({super.key});

  @override
  State<AdminUserListView> createState() => _AdminUserListViewState();
}

class _AdminUserListViewState extends State<AdminUserListView> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await ApiService.getAllUsers();
      setState(() {
        _users = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Management", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text("No users found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final String role = user['role'] ?? 'user';
                    final bool isAdmin = role == 'admin';
                    
                    // Format tanggal join (jika ada created_at)
                    String joinDate = user['created_at'] ?? '';
                    if (joinDate.length > 10) joinDate = joinDate.substring(0, 10);

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200)
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: isAdmin ? Colors.red : Colors.blue,
                          ),
                        ),
                        title: Text(
                          user['full_name'] ?? 'No Name', 
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold)
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'], style: const TextStyle(fontSize: 12)),
                            Text("Joined: $joinDate", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          // NAVIGASI KE DETAIL HISTORY USER TERSEBUT
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminUserHistoryPage(
                                userId: user['id'], 
                                userName: user['full_name'] ?? 'User'
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class AdminUserHistoryPage extends StatefulWidget {
  final String userId;
  final String userName;
  
  const AdminUserHistoryPage({
    super.key, 
    required this.userId, 
    required this.userName
  });

  @override
  State<AdminUserHistoryPage> createState() => _AdminUserHistoryPageState();
}

class _AdminUserHistoryPageState extends State<AdminUserHistoryPage> {
  List<dynamic> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserHistory();
  }

  Future<void> _fetchUserHistory() async {
    try {
      final data = await ApiService.getAdminUserHistory(widget.userId);
      setState(() {
        _historyList = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- LOGIC DELETE ITEM ---
  Future<void> _deleteItem(int index) async {
    final item = _historyList[index];
    final String historyId = item['id'];

    // 1. Konfirmasi Dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete this record?"),
        content: Text("This action will verify remove this image from ${widget.userName}'s history."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Cancel")
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
 
      bool success = await ApiService.deleteHistoryItem(historyId);
      
      if (success) {
        setState(() {
          _historyList.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Record deleted successfully."))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete. Check admin permissions."))
        );
      }
    }
  }

  // --- HELPER WARNA & LABEL ---
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${widget.userName}'s History", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Admin View", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text("${widget.userName} hasn't uploaded any images yet.", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyList.length,
                  itemBuilder: (context, index) {
                    final item = _historyList[index];
                    
                    final int score = item['score'] is int 
                        ? item['score'] 
                        : int.tryParse(item['score'].toString()) ?? 0;
                    
                    String dateStr = item['date'].toString();
                    if (dateStr.length > 16) dateStr = dateStr.substring(0, 16);

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
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100, height: 100, color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
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
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(score).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "MES $score",
                                          style: TextStyle(
                                            color: _getStatusColor(score),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12
                                          ),
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getLabel(score),
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ID: ${item['id']}", 
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // --- 3. TOMBOL DELETE (TRASH) KHUSUS ADMIN ---
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                            tooltip: "Admin Delete",
                            onPressed: () => _deleteItem(index),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}