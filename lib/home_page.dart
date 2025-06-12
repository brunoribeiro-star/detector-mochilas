import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _imageFile;
  Uint8List? _imageBytes;
  String _result = '';
  String? _imageUrl;
  bool _loading = false;
  bool _isZoomed = false;

  // Histórico de imagens analisadas
  final List<HistoryItem> _history = [];

  final Color primary = const Color(0xFF246bfd);
  final Color secondary = const Color(0xFF6c47ff);
  final Color background = const Color(0xFFf7f8fa);

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _result = '';
        _loading = true;
        _imageUrl = null;
      });

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _imageBytes = bytes);
        await _uploadImageWeb(bytes, pickedFile.name);
      } else {
        final imageFile = File(pickedFile.path);
        setState(() => _imageFile = imageFile);
        await _uploadImage(imageFile);
      }
    }
  }

  Future<void> _uploadImage(File image) async {
    final uri = Uri.parse('http://192.168.100.3:5000/detect');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final decoded = json.decode(respStr);
        setState(() {
          _loading = false;
          _imageUrl = decoded['image_url'];
          final detections = decoded['detections'] as List;
          if (detections.isNotEmpty) {
            _result = detections
                .map((d) => "${d['name']} - Confiança: ${(d['confidence'] * 100).toStringAsFixed(1)}%")
                .join('\n');
          } else {
            _result = 'Nenhum objeto reconhecido.';
          }
        });
        _saveToHistory();
      } else {
        setState(() {
          _loading = false;
          _result = 'Erro na detecção.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _result = 'Erro: $e';
      });
    }
  }

  Future<void> _uploadImageWeb(Uint8List bytes, String filename) async {
    final uri = Uri.parse('http://192.168.100.3:5000/detect');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final decoded = json.decode(respStr);
        setState(() {
          _loading = false;
          _imageUrl = decoded['image_url'];
          final detections = decoded['detections'] as List;
          if (detections.isNotEmpty) {
            _result = detections
                .map((d) => "${d['name']} - Confiança: ${(d['confidence'] * 100).toStringAsFixed(1)}%")
                .join('\n');
          } else {
            _result = 'Nenhum objeto reconhecido.';
          }
        });
        _saveToHistory();
      } else {
        setState(() {
          _loading = false;
          _result = 'Erro na detecção.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _result = 'Erro: $e';
      });
    }
  }

  // Salva a análise atual no histórico
  void _saveToHistory() {
    if (_imageUrl != null && _result.isNotEmpty) {
      setState(() {
        _history.add(HistoryItem(
          imageUrl: _imageUrl!,
          result: _result,
        ));
      });
    }
  }

  Widget _imageDisplay({bool zoomed = false}) {
    final imageWidget = _loading
        ? const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: CircularProgressIndicator(),
    )
        : _imageUrl != null
        ? Image.network(
      _imageUrl!,
      height: zoomed ? null : 280,
      width: zoomed ? double.infinity : null,
      fit: BoxFit.contain,
    )
        : kIsWeb && _imageBytes != null
        ? Image.memory(
      _imageBytes!,
      height: zoomed ? null : 240,
      width: zoomed ? double.infinity : null,
      fit: BoxFit.contain,
    )
        : _imageFile != null
        ? Image.file(
      _imageFile!,
      height: zoomed ? null : 240,
      width: zoomed ? double.infinity : null,
      fit: BoxFit.contain,
    )
        : const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text('Nenhuma imagem selecionada', style: TextStyle(color: Colors.grey)),
    );

    if (_imageUrl == null && _imageBytes == null && _imageFile == null) {
      // Nenhuma imagem, retorna widget de texto
      return imageWidget;
    }

    return Stack(
      alignment: Alignment.topRight,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _isZoomed = true);
            if (!zoomed) {
              _showImageFullScreen();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: imageWidget,
          ),
        ),
        if (!zoomed)
          Positioned(
            top: 14,
            right: 14,
            child: Material(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                onTap: () {
                  setState(() => _isZoomed = true);
                  _showImageFullScreen();
                },
                borderRadius: BorderRadius.circular(50),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.zoom_in, size: 28, color: Color(0xFF246bfd)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showImageFullScreen() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.97),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: SingleChildScrollView(
                child: _imageDisplay(zoomed: true),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Material(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _isZoomed = false);
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(Icons.zoom_out, size: 28, color: Color(0xFF246bfd)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO/ICON
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.backpack_rounded, size: 42, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    // Mensagem institucional
                    Text(
                      "Detector de Mochilas por IA",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primary,
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sua segurança, tecnologia e praticidade em um só app.\n"
                          "Identifique mochilas em imagens de forma rápida e confiável, utilizando Inteligência Artificial.",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Imagem exibida/processada com lupa
                    _imageDisplay(),
                    const SizedBox(height: 10),
                    // Resultado
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _result.isEmpty ? 'Envie uma imagem para análise.' : _result,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, color: primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botões bonitos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text("Tirar Foto"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            elevation: 1.5,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Galeria"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            elevation: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "© 2024 - Projeto de Detecção de Mochilas por IA",
                      style: TextStyle(fontSize: 13, color: Colors.black38),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Botão de histórico fixo no topo direito
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.history_rounded, size: 34, color: primary),
                  tooltip: "Ver histórico",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HistoryPage(history: _history),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}