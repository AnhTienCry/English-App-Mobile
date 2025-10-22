import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import '../services/tts_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  
  String _sourceLanguage = 'en';
  String _targetLanguage = 'vi';
  bool _isLoading = false;
  String _error = '';
  
  // Danh sách ngôn ngữ hỗ trợ
  final Map<String, String> _languages = {
    'en': 'English',
    'vi': 'Tiếng Việt',
    'ja': '日本語',
    'ko': '한국어',
    'zh': '中文',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'ar': 'العربية',
    'th': 'ไทย',
    'hi': 'हिन्दी',
  };

  @override
  void initState() {
    super.initState();
    TTSService().initialize();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  /// Hoán đổi ngôn ngữ nguồn và đích
  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
      
      // Hoán đổi text
      final tempText = _sourceController.text;
      _sourceController.text = _targetController.text;
      _targetController.text = tempText;
    });
  }

  /// Dịch text
  Future<void> _translate() async {
    if (_sourceController.text.trim().isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập text cần dịch';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Sử dụng endpoint custom translation
      final response = await dio.post(
        '${ApiConfig.translationEndpoint}/custom',
        data: {
          'text': _sourceController.text.trim(),
          'source': _sourceLanguage,
          'target': _targetLanguage,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _targetController.text = response.data['translatedText'] ?? '';
        });
      } else {
        setState(() {
          _error = 'Lỗi dịch thuật: ${response.data['error']?['message'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Copy text to clipboard
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã copy vào clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Phát âm text
  void _speakText(String text, String language) {
    if (text.trim().isEmpty) return;
    
    if (language == 'en') {
      TTSService().speakUS(text);
    } else if (language == 'vi') {
      TTSService().speak(text); // Fallback to default
    } else {
      TTSService().speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Dịch Thuật',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Language Selection Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Source Language
                Expanded(
                  child: _buildLanguageSelector(
                    'Từ',
                    _sourceLanguage,
                    (value) => setState(() => _sourceLanguage = value!),
                  ),
                ),
                
                // Swap Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: IconButton(
                    onPressed: _swapLanguages,
                    icon: Icon(
                      Icons.swap_horiz,
                      color: Colors.blue.shade600,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
                
                // Target Language
                Expanded(
                  child: _buildLanguageSelector(
                    'Sang',
                    _targetLanguage,
                    (value) => setState(() => _targetLanguage = value!),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Translation Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Source Text Area
                  Expanded(
                    child: _buildTextArea(
                      controller: _sourceController,
                      hintText: 'Nhập text cần dịch...',
                      onChanged: (text) {
                        if (text.trim().isNotEmpty) {
                          _translate();
                        }
                      },
                      onSpeak: () => _speakText(_sourceController.text, _sourceLanguage),
                      onCopy: () => _copyToClipboard(_sourceController.text),
                    ),
                  ),
                  
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  
                  // Target Text Area
                  Expanded(
                    child: _buildTextArea(
                      controller: _targetController,
                      hintText: 'Bản dịch sẽ hiển thị ở đây...',
                      isReadOnly: true,
                      isLoading: _isLoading,
                      onSpeak: () => _speakText(_targetController.text, _targetLanguage),
                      onCopy: () => _copyToClipboard(_targetController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Error Message
          if (_error.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Build language selector dropdown
  Widget _buildLanguageSelector(String label, String selectedLanguage, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: selectedLanguage,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build text area with actions
  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
    bool isReadOnly = false,
    bool isLoading = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onSpeak,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onSpeak != null)
                IconButton(
                  onPressed: controller.text.trim().isEmpty ? null : onSpeak,
                  icon: Icon(
                    Icons.volume_up,
                    color: controller.text.trim().isEmpty ? Colors.grey : Colors.blue.shade600,
                    size: 20,
                  ),
                  tooltip: 'Phát âm',
                ),
              if (onCopy != null)
                IconButton(
                  onPressed: controller.text.trim().isEmpty ? null : onCopy,
                  icon: Icon(
                    Icons.copy,
                    color: controller.text.trim().isEmpty ? Colors.grey : Colors.grey.shade600,
                    size: 20,
                  ),
                  tooltip: 'Copy',
                ),
            ],
          ),
          
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: isReadOnly,
              onChanged: onChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // Loading indicator
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đang dịch...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
