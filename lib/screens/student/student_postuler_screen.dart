import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

class StudentPostulerScreen extends StatefulWidget {
  final Map<String, dynamic> offre;

  const StudentPostulerScreen({super.key, required this.offre});

  @override
  State<StudentPostulerScreen> createState() => _StudentPostulerScreenState();
}

class _StudentPostulerScreenState extends State<StudentPostulerScreen> {
  final _api = ApiClient.instance;
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _submitting = false;

  // Controllers
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _rgpd = false;

  // Fichiers
  PlatformFile? _cvFile;
  PlatformFile? _lmFile;
  PlatformFile? _recFile;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final profil = await _api.get('/profils/moi');
      final etudiant = profil['etudiant'];
      if (etudiant != null) {
        setState(() {
          _emailCtrl.text = etudiant['email'] ?? '';
          _telCtrl.text = etudiant['telephone'] ?? '';
          _villeCtrl.text = etudiant['ville'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() {
        if (type == 'cv') _cvFile = result.files.first;
        if (type == 'lm') _lmFile = result.files.first;
        if (type == 'rec') _recFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadFile(PlatformFile? file, String bucket) async {
    if (file == null || file.bytes == null) return null;
    try {
      final uploadInfo = await _api.post('/candidatures/upload-url', {
        'bucket': bucket,
        'nom_fichier': file.name,
      });
      final uploadUrl = uploadInfo['upload_url'];
      final cleFichier = uploadInfo['cle_fichier'];

      final res = await http.put(
        Uri.parse(uploadUrl),
        body: file.bytes,
        headers: {'Content-Type': 'application/octet-stream'},
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final publicRes = await _api
            .get('/candidatures/public-url?bucket=$bucket&path=$cleFichier');
        return publicRes['url'];
      }
    } catch (e) {
      debugPrint('Erreur upload $bucket: $e');
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // ...
    if (_cvFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez ajouter votre CV')));
      return;
    }
    if (!_rgpd) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez accepter les conditions')));
      return;
    }

    setState(() => _submitting = true);

    try {
      final cvUrl = await _uploadFile(_cvFile, 'cvs');
      final lmUrl = await _uploadFile(_lmFile, 'lettres-motivation');
      final recUrl = await _uploadFile(_recFile, 'recommandations');

      final payload = {
        'offreId': widget.offre['id'],
        'email': _emailCtrl.text.trim(),
        'telephone': _telCtrl.text.trim(),
        'localisation': _villeCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'cv_url': cvUrl,
        'lettre_motivation_url': lmUrl,
        'lettre_recommandation_url': recUrl,
        'certification_exactitude': _rgpd,
      };

      await _api.post('/candidatures', payload);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Succès'),
            content:
                const Text('Votre candidature a été envoyée avec succès !'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Postuler',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              // En-tête de l'offre
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                color: AppColors.gold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OFFRE SÉLECTIONNÉE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.offre['titre'] ?? 'Offre sans titre',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('Vos coordonnées',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.darkGreen)),
                      const SizedBox(height: 15),
                      _buildStyledField(_emailCtrl, 'Email *',
                          placeholder: 'votre@email.com', required: true),
                      const SizedBox(height: 15),
                      _buildStyledField(_telCtrl, 'Téléphone *',
                          placeholder: '+237 ...', required: true),
                      const SizedBox(height: 15),
                      _buildStyledField(_villeCtrl, 'Localisation *',
                          placeholder: 'Ville, Pays', required: true),
                      const SizedBox(height: 25),
                      const Text('Documents & Motivation',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.darkGreen)),
                      const SizedBox(height: 15),
                      _fileUploadTile(
                          'CV (PDF) *', _cvFile, () => _pickFile('cv'),
                          required: true),
                      _fileUploadTile('Lettre de motivation', _lmFile,
                          () => _pickFile('lm')),
                      _fileUploadTile('Lettre de recommandation (Optionnel)',
                          _recFile, () => _pickFile('rec')),
                      const SizedBox(height: 15),
                      _buildStyledField(
                          _messageCtrl, 'Description / Motivation',
                          placeholder:
                              'Décrivez brièvement votre motivation...',
                          maxLines: 4),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _rgpd,
                              activeColor: AppColors.darkGreen,
                              onChanged: (v) => setState(() => _rgpd = v!),
                            ),
                            const Expanded(
                              child: Text(
                                'Je certifie l\'exactitude des informations fournies et j\'accepte le traitement de mes données personnelles.',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _buildBottomButton(),
    );
  }

  Widget _buildStyledField(TextEditingController ctrl, String label,
      {String? placeholder, bool required = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: appInputDecoration(hint: placeholder),
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Champ requis' : null
              : null,
        ),
      ],
    );
  }

  Widget _fileUploadTile(String label, PlatformFile? file, VoidCallback onTap,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
                color:
                    file != null ? AppColors.darkGreen : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color:
                file != null ? AppColors.sage.withOpacity(0.1) : Colors.white,
          ),
          child: Row(
            children: [
              Icon(Icons.file_present,
                  color: file != null ? AppColors.darkGreen : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(file?.name ?? 'Sélectionner un fichier',
                        style: TextStyle(
                            fontSize: 11,
                            color: file != null
                                ? AppColors.darkGreen
                                : AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.upload, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardGrey, width: 0.5)),
      ),
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _submitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Envoyer ma candidature',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
