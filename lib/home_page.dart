import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String _result = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
        _result = '';
      });
      await _uploadImage(imageFile);
    }
  }

  Future<void> _uploadImage(File image) async {
    final uri = Uri.parse('http://172.32.174.171:5000/detect');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', image.path)); // Corrigido

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final decoded = json.decode(respStr);
        setState(() {
          final detections = decoded['detections'] as List;
          if (detections.isNotEmpty) {
            _result = detections
                .map((d) => "${d['name']} - ${d['confidence'].toStringAsFixed(2)}")
                .join('\n');
          } else {
            _result = 'Nenhum objeto reconhecido.';
          }
        });
      } else {
        setState(() {
          _result = 'Erro na detecção.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detector de Objetos')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image != null
                  ? Image.file(_image!, height: 200)
                  : const Text('Nenhuma imagem selecionada'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Tirar Foto'),
              ),
              const SizedBox(height: 20),
              Text(
                _result,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
