import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Recognition',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TextRecognitionScreen(),
    );
  }
}

class TextRecognitionScreen extends StatefulWidget {
  @override
  _TextRecognitionScreenState createState() => _TextRecognitionScreenState();
}

class _TextRecognitionScreenState extends State<TextRecognitionScreen> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String _recognizedText = '';
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  late final TextRecognizer _textRecognizer;

  @override
  void initState() {
    super.initState();
    _initializeTextRecognizer();
  }

  void _initializeTextRecognizer() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // Função para pegar imagem da galeria
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _imageFile = image;
          _imageBytes = imageBytes;
          _recognizedText = '';
        });
        await _recognizeText();
      }
    } catch (e) {
      _showSnackBar('Erro ao selecionar imagem: $e');
    }
  }

  // Função para tirar foto com a câmera
  Future<void> _pickImageFromCamera() async {
    // Verificar se está no mobile
    if (kIsWeb) {
      _showSnackBar('Câmera não suportada no Flutter Web');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _imageFile = image;
          _imageBytes = imageBytes;
          _recognizedText = '';
        });
        await _recognizeText();
      }
    } catch (e) {
      _showSnackBar('Erro ao tirar foto: $e');
    }
  }

  // Função principal para reconhecer texto
  Future<void> _recognizeText() async {
    if (_imageFile == null) return;

    // Verificar se está no web
    if (kIsWeb) {
      _showSnackBar('ML Kit Text Recognition não funciona no Flutter Web. Use em dispositivos móveis.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final InputImage inputImage = InputImage.fromFilePath(_imageFile!.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        _recognizedText = recognizedText.text;
        _isLoading = false;
      });

      // Debug: imprimir blocos de texto encontrados
      print('Texto completo: ${recognizedText.text}');
      for (TextBlock block in recognizedText.blocks) {
        print('Bloco: ${block.text}');
        for (TextLine line in block.lines) {
          print('Linha: ${line.text}');
        }
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erro no reconhecimento: $e');
      print('Erro detalhado: $e');
    }
  }

  // Função para mostrar mensagens
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Função para limpar tudo
  void _clearAll() {
    setState(() {
      _imageFile = null;
      _imageBytes = null;
      _recognizedText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reconhecimento de Texto'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_imageFile != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearAll,
              tooltip: 'Limpar',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botões para selecionar imagem
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Galeria'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Câmera'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Mostrar imagem selecionada
            if (_imageBytes != null) ...[
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Loading ou botão de reconhecer
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Reconhecendo texto...'),
                  ],
                ),
              )
            else if (_imageFile != null && _recognizedText.isEmpty)
              ElevatedButton(
                onPressed: _recognizeText,
                child: Text('Reconhecer Texto'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

            SizedBox(height: 20),

            // Mostrar texto reconhecido
            if (_recognizedText.isNotEmpty) ...[
              Text(
                'Texto Reconhecido:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _recognizedText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  // Copiar texto para clipboard
                  // Clipboard.setData(ClipboardData(text: _recognizedText));
                  _showSnackBar('Texto copiado!');
                },
                icon: Icon(Icons.copy),
                label: Text('Copiar Texto'),
              ),
            ],

            if (_recognizedText.isEmpty && _imageFile == null) ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.text_fields,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Selecione uma imagem para reconhecer o texto',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Exemplo de uso mais específico para o gabarito
class GabaritoProcessor {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<Map<int, String>> processGabarito(XFile imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      Map<int, String> gabarito = {};

      // Processar cada linha do texto reconhecido
      List<String> lines = recognizedText.text.split('\n');

      for (String line in lines) {
        // Buscar padrão como "01. A", "02. C", etc.
        RegExp regex = RegExp(r'(\d+)\.\s*([A-E])');
        Match? match = regex.firstMatch(line.trim());

        if (match != null) {
          int questao = int.parse(match.group(1)!);
          String resposta = match.group(2)!;
          gabarito[questao] = resposta;
        }
      }

      return gabarito;
    } catch (e) {
      print('Erro ao processar gabarito: $e');
      return {};
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}