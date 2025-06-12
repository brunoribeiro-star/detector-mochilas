import 'package:flutter/material.dart';

class HistoryItem {
  final String imageUrl;
  final String result;

  HistoryItem({required this.imageUrl, required this.result});
}

class HistoryPage extends StatefulWidget {
  final List<HistoryItem> history;

  const HistoryPage({super.key, required this.history});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Color primary = const Color(0xFF246bfd);
  final Color secondary = const Color(0xFF6c47ff);
  final Color background = const Color(0xFFf7f8fa);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF246bfd)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Histórico',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primary,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 18, right: 18, bottom: 2),
            child: Text(
              "Aqui você pode visualizar as mochilas detectadas pelo sistema durante essa sessão.",
              style: TextStyle(fontSize: 15, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: widget.history.isEmpty
                ? Center(
              child: Text(
                "Nenhuma imagem no histórico!",
                style: TextStyle(color: Colors.black38, fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.history.length,
              itemBuilder: (ctx, i) {
                final item = widget.history[widget.history.length - 1 - i]; // Último primeiro
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      item.result.length > 35
                          ? item.result.substring(0, 34) + '...'
                          : item.result,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      item.imageUrl,
                      style: const TextStyle(fontSize: 11, color: Colors.black38),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}