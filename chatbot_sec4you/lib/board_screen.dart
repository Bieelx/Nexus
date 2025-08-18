import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'local_data.dart';

class BoardScreen extends StatefulWidget {
  final String boardName;
  const BoardScreen({super.key, required this.boardName});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  List posts = [];
  final TextEditingController _controller = TextEditingController();
  File? _image;
  Map<String, dynamic>? _replyTo;

  @override
  void initState() {
    super.initState();
    posts = LocalData().getPosts(widget.boardName);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

void sendPost() async {
  if (_controller.text.trim().isEmpty && _image == null) return;
  await LocalData().addPost(
    widget.boardName,
    _controller.text,
    _image?.path,
    replyTo: _replyTo, // Não passa parentId!
  );
  setState(() {
    posts = LocalData().getPosts(widget.boardName);
    _controller.clear();
    _image = null;
    _replyTo = null;
  });
}

  void showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName, style: const TextStyle(color: Color(0xFFFAF9F6))),
        iconTheme: const IconThemeData(color: Color(0xFFFAF9F6)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: posts.reversed.map<Widget>((p) => GestureDetector(
                onLongPress: () {
                  setState(() {
                    _replyTo = {
                      'id': p['id'],
                      'text': p['text'],
                      'image': p['image'],
                    };
                  });
                  // Removido o SnackBar!
                },
                child: Card(
                  color: const Color(0xFF232323),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p['replyTo'] != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                const Icon(Icons.reply, color: Color(0xFF7F2AB1), size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (p['replyTo']['text'] != null && p['replyTo']['text'] != '')
                                        Text(
                                          p['replyTo']['text'],
                                          style: const TextStyle(
                                            color: Color(0xFFFAF9F6),
                                            fontStyle: FontStyle.italic,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (p['replyTo']['image'] != null && p['replyTo']['image'] != '')
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: GestureDetector(
                                            onTap: () => showFullImage(p['replyTo']['image']),
                                            child: Image.file(
                                              File(p['replyTo']['image']),
                                              height: 40,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (p['image'] != null && p['image'] != '')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => showFullImage(p['image']),
                              child: Image.file(
                                File(p['image']),
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Text(
                          p['text'] ?? '',
                          style: const TextStyle(color: Color(0xFFFAF9F6), fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p['date'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          if (_replyTo != null)
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.reply, color: Color(0xFF7F2AB1), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_replyTo!['text'] != null && _replyTo!['text'] != '')
                          Text(
                            _replyTo!['text'],
                            style: const TextStyle(
                              color: Color(0xFFFAF9F6),
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (_replyTo!['image'] != null && _replyTo!['image'] != '')
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Image.file(
                              File(_replyTo!['image']),
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Color(0xFF7F2AB1)),
                  onPressed: pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Color(0xFFFAF9F6)),
                    decoration: const InputDecoration(
                      hintText: 'Escreva algo...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF7F2AB1)),
                  onPressed: sendPost,
                ),
              ],
            ),
          ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Image.file(_image!, height: 80),
            ),
        ],
      ),
    );
  }
}