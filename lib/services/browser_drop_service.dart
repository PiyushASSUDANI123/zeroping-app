import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class BrowserDropService extends ChangeNotifier {
  HttpServer? _server;
  int port = 8080;
  bool _isRunning = false;
  String _hostIp = '';

  bool get isRunning => _isRunning;
  String get hostIp => _hostIp;
  String get webUrl => _isRunning ? 'http://$_hostIp:$port' : '';

  Future<bool> startServer({required String hostIp, int serverPort = 8080}) async {
    if (_isRunning) return true;

    _hostIp = hostIp;
    port = serverPort;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server?.listen(_handleHttpRequest, onError: (e) {
        debugPrint('BrowserDrop server error: $e');
      });

      _isRunning = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to bind BrowserDrop HTTP server: $e');
      _isRunning = false;
      notifyListeners();
      return false;
    }
  }

  void stopServer() {
    _server?.close(force: true);
    _server = null;
    _isRunning = false;
    notifyListeners();
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    // CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    try {
      if (path == '/' || path == '/index.html') {
        await _serveWebPage(request);
      } else if (path == '/api/files') {
        await _handleListFiles(request);
      } else if (path.startsWith('/download/')) {
        await _handleDownloadFile(request);
      } else if (path == '/upload' && request.method == 'POST') {
        await _handleUploadFile(request);
      } else if (path == '/api/clipboard' && request.method == 'GET') {
        final clip = await Clipboard.getData(Clipboard.kTextPlain);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'text': clip?.text ?? ''}));
        await request.response.close();
      } else if (path == '/api/clipboard' && request.method == 'POST') {
        final body = await utf8.decodeStream(request);
        final map = jsonDecode(body) as Map<String, dynamic>;
        final text = map['text'] as String? ?? '';
        if (text.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: text));
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'status': 'ok'}));
        await request.response.close();
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not Found');
        await request.response.close();
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Server Error: $e');
      await request.response.close();
    }
  }

  Future<void> _handleListFiles(HttpRequest request) async {
    final dir = await StorageService.getDownloadsDirectoryPath();
    final List<Map<String, dynamic>> filesList = [];

    if (await dir.exists()) {
      final list = dir.listSync();
      for (final entity in list) {
        if (entity is File) {
          final stat = entity.statSync();
          final name = entity.path.split(RegExp(r'[/\\]')).last;
          filesList.add({
            'name': name,
            'size': stat.size,
            'modified': stat.modified.toIso8601String(),
          });
        }
      }
    }

    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(filesList));
    await request.response.close();
  }

  Future<void> _handleDownloadFile(HttpRequest request) async {
    final fileName = Uri.decodeComponent(request.uri.path.replaceFirst('/download/', ''));
    final dir = await StorageService.getDownloadsDirectoryPath();
    final file = File('${dir.path}/$fileName');

    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('File not found');
      await request.response.close();
      return;
    }

    request.response.headers.contentType = ContentType.binary;
    request.response.headers.add(
      'Content-Disposition',
      'attachment; filename="$fileName"',
    );
    request.response.headers.contentLength = await file.length();

    await file.openRead().pipe(request.response);
  }

  Future<void> _handleUploadFile(HttpRequest request) async {
    final fileNameHeader = request.headers.value('x-filename');
    final fileName = fileNameHeader != null && fileNameHeader.isNotEmpty
        ? Uri.decodeComponent(fileNameHeader)
        : 'drop_${DateTime.now().millisecondsSinceEpoch}.bin';

    final dir = await StorageService.getDownloadsDirectoryPath();
    final targetFile = File('${dir.path}/$fileName');

    final sink = targetFile.openWrite();
    await for (final chunk in request) {
      sink.add(chunk);
    }
    await sink.flush();
    await sink.close();

    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({'status': 'success', 'fileName': fileName}));
    await request.response.close();
    notifyListeners();
  }

  Future<void> _serveWebPage(HttpRequest request) async {
    request.response.headers.contentType = ContentType.html;
    request.response.write('''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ZeroPing • Browser Drop</title>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; font-family:-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    body { background: #080C14; color: #F8FAFC; min-height: 100vh; display: flex; flex-direction: column; align-items: center; padding: 30px 16px; }
    .container { width: 100%; max-width: 820px; }
    header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; padding-bottom: 16px; border-bottom: 1px solid rgba(255,255,255,0.1); }
    .logo { font-size: 22px; font-weight: 800; background: linear-gradient(135deg, #00F0FF, #8B5CF6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .badge { font-size: 11px; padding: 4px 10px; border-radius: 20px; background: rgba(0, 240, 255, 0.12); color: #00F0FF; border: 1px solid rgba(0, 240, 255, 0.3); }
    
    .drop-zone {
      border: 2px dashed rgba(0, 240, 255, 0.4);
      background: rgba(15, 23, 42, 0.6);
      backdrop-filter: blur(16px);
      border-radius: 20px;
      padding: 40px 20px;
      text-align: center;
      cursor: pointer;
      transition: all 0.25s ease;
      margin-bottom: 24px;
    }
    .drop-zone:hover, .drop-zone.dragover { border-color: #00F0FF; background: rgba(0, 240, 255, 0.08); transform: translateY(-2px); }
    .drop-zone h3 { font-size: 18px; margin-bottom: 6px; color: #F8FAFC; }
    .drop-zone p { font-size: 13px; color: #94A3B8; }
    
    .card { background: rgba(19, 29, 49, 0.7); backdrop-filter: blur(12px); border-radius: 18px; border: 1px solid rgba(255,255,255,0.08); padding: 20px; margin-bottom: 24px; }
    .card h2 { font-size: 16px; font-weight: 700; margin-bottom: 14px; color: #00F0FF; display: flex; align-items: center; gap: 8px; }
    
    .clipboard-box { display: flex; gap: 10px; }
    input[type="text"] { flex: 1; background: #080C14; border: 1px solid rgba(255,255,255,0.15); border-radius: 10px; padding: 12px; color: #FFF; font-size: 14px; outline: none; }
    input[type="text"]:focus { border-color: #00F0FF; }
    button { background: #00F0FF; color: #000; border: none; font-weight: 700; padding: 12px 20px; border-radius: 10px; cursor: pointer; transition: 0.2s; }
    button:hover { opacity: 0.9; transform: translateY(-1px); }
    
    .file-item { display: flex; justify-content: space-between; align-items: center; padding: 12px 14px; background: rgba(255,255,255,0.03); border-radius: 12px; margin-bottom: 8px; }
    .file-name { font-size: 14px; font-weight: 500; }
    .file-size { font-size: 11px; color: #94A3B8; }
    .download-btn { background: rgba(0, 230, 118, 0.15); color: #00E676; border: 1px solid rgba(0, 230, 118, 0.4); padding: 6px 14px; font-size: 12px; border-radius: 8px; text-decoration: none; font-weight: 600; }
    .download-btn:hover { background: #00E676; color: #000; }
    
    #progress-container { display: none; margin-top: 14px; }
    .progress-bar { width: 100%; height: 8px; background: #080C14; border-radius: 10px; overflow: hidden; }
    .progress-fill { height: 100%; width: 0%; background: linear-gradient(90deg, #00F0FF, #8B5CF6); transition: width 0.1s ease; }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div class="logo">ZeroPing • Browser Drop</div>
      <div class="badge">LAN Connected (Direct)</div>
    </header>

    <div class="drop-zone" id="drop-zone" onclick="document.getElementById('file-input').click()">
      <h3>Drag & Drop Files Here</h3>
      <p>Or click to select any file from your PC (Instant sync to phone)</p>
      <input type="file" id="file-input" style="display:none" onchange="handleFileSelect(this.files)">
      
      <div id="progress-container">
        <div class="progress-bar"><div class="progress-fill" id="progress-fill"></div></div>
        <p id="progress-text" style="margin-top:6px; font-size:12px; color:#00F0FF;">Uploading...</p>
      </div>
    </div>

    <div class="card">
      <h2>📋 Universal Clipboard Sync</h2>
      <div class="clipboard-box">
        <input type="text" id="clip-input" placeholder="Type or paste text/OTP to sync instantly to phone...">
        <button onclick="sendClipboard()">Push to Phone</button>
      </div>
    </div>

    <div class="card">
      <h2>📁 Phone Vault Files (Click to Download)</h2>
      <div id="file-list">Loading files from phone...</div>
    </div>
  </div>

  <script>
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('file-input');

    ['dragenter', 'dragover'].forEach(name => {
      dropZone.addEventListener(name, (e) => { e.preventDefault(); dropZone.classList.add('dragover'); });
    });
    ['dragleave', 'drop'].forEach(name => {
      dropZone.addEventListener(name, (e) => { e.preventDefault(); dropZone.classList.remove('dragover'); });
    });

    dropZone.addEventListener('drop', (e) => {
      const files = e.dataTransfer.files;
      if (files.length) handleFileSelect(files);
    });

    function handleFileSelect(files) {
      if (!files.length) return;
      const file = files[0];
      uploadFile(file);
    }

    function uploadFile(file) {
      const pContainer = document.getElementById('progress-container');
      const pFill = document.getElementById('progress-fill');
      const pText = document.getElementById('progress-text');
      pContainer.style.display = 'block';

      const xhr = new XMLHttpRequest();
      xhr.open('POST', '/upload', true);
      xhr.setRequestHeader('x-filename', encodeURIComponent(file.name));

      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) {
          const percent = Math.round((e.loaded / e.total) * 100);
          pFill.style.width = percent + '%';
          pText.innerText = 'Streaming: ' + percent + '% (' + (e.loaded / (1024*1024)).toFixed(1) + ' MB)';
        }
      };

      xhr.onload = () => {
        pText.innerText = 'Uploaded Successfully: ' + file.name + ' ✅';
        setTimeout(() => { pContainer.style.display = 'none'; pFill.style.width = '0%'; }, 2500);
        loadFiles();
      };

      xhr.send(file);
    }

    function loadFiles() {
      fetch('/api/files')
        .then(r => r.json())
        .then(files => {
          const container = document.getElementById('file-list');
          if (!files.length) {
            container.innerHTML = '<p style="color:#64748B; font-size:13px;">No files in Phone Vault yet.</p>';
            return;
          }
          container.innerHTML = files.map(f => `
            <div class="file-item">
              <div>
                <div class="file-name">\${f.name}</div>
                <div class="file-size">\${(f.size / (1024*1024)).toFixed(2)} MB</div>
              </div>
              <a href="/download/\${encodeURIComponent(f.name)}" class="download-btn">Download</a>
            </div>
          `).join('');
        });
    }

    function sendClipboard() {
      const input = document.getElementById('clip-input');
      const text = input.value.trim();
      if (!text) return;
      fetch('/api/clipboard', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text })
      }).then(() => {
        alert('Pushed to Phone Clipboard! ⚡');
        input.value = '';
      });
    }

    loadFiles();
  </script>
</body>
</html>''');
    await request.response.close();
  }

  @override
  void dispose() {
    stopServer();
    super.dispose();
  }
}
