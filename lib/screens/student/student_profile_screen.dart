import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/services/api_client.dart';
import '../../core/services/auth_provider.dart';
import '../../theme/app_colors.dart';

/// Cas d'utilisation "Gérer profil" : photo, filière, spécialité, niveau,
/// compétences, centres d'intérêt, upload de CV, notes (images de
/// bulletins), recommandations personnalisées (spécialités, technologies,
/// certifications, formations, métiers).
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _api = ApiClient.instance;

  // Valeurs valides pour l'enum "niveau_etudiant" côté base de données.
  static const List<String> _niveauxValides = ['I', 'II', 'III'];

  Map<String, dynamic>? _profil;
  List<dynamic> _recommandations = [];
  bool _loading = true;
  bool _loadingRecommandations = false;
  bool _uploadingPhoto = false;
  bool _uploadingCv = false;
  String? _error;

  final _competenceCtrl = TextEditingController();
  final _interetCtrl = TextEditingController();
  String _niveauCompetence = 'debutant';

  // Identifiant de la note en cours d'upload ("_new" pour une création),
  // utilisé pour afficher un indicateur de chargement ciblé et désactiver
  // les actions concurrentes.
  String? _uploadingNoteId;

  List<dynamic> get _notes => (_profil?['notes'] as List?) ?? [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _competenceCtrl.dispose();
    _interetCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Chargement des données
  // ---------------------------------------------------------------------

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get('/profils/moi');
      setState(() => _profil = data);
      _loadRecommandations();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRecommandations() async {
    setState(() => _loadingRecommandations = true);
    try {
      final data = await _api.get('/profils/moi/recommandations');
      setState(
          () => _recommandations = (data?['recommandations'] as List?) ?? []);
    } catch (_) {
      // Les recommandations ne sont pas bloquantes pour l'affichage du profil.
      setState(() => _recommandations = []);
    } finally {
      setState(() => _loadingRecommandations = false);
    }
  }

  // ---------------------------------------------------------------------
  // Compétences / centres d'intérêt
  // ---------------------------------------------------------------------

  Future<void> _addCompetence() async {
    if (_competenceCtrl.text.trim().isEmpty) return;
    await _api.post('/profils/moi/competences', {
      'competence_nom': _competenceCtrl.text.trim(),
      'niveau': _niveauCompetence,
    });
    _competenceCtrl.clear();
    _load();
  }

  Future<void> _removeCompetence(dynamic competenceId) async {
    if (competenceId == null) return;
    await _api.delete('/profils/moi/competences/$competenceId');
    _load();
  }

  Future<void> _addInteret() async {
    if (_interetCtrl.text.trim().isEmpty) return;
    await _api
        .post('/profils/moi/interets', {'domaine': _interetCtrl.text.trim()});
    _interetCtrl.clear();
    _load();
  }

  Future<void> _removeInteret(dynamic interetId) async {
    if (interetId == null) return;
    await _api.delete('/profils/moi/interets/$interetId');
    _load();
  }

  // ---------------------------------------------------------------------
  // Notes (images de bulletins) : CRUD complet, même principe que le CV
  // (URL signée -> upload direct -> confirmation côté API).
  // ---------------------------------------------------------------------

  /// Ajoute une nouvelle note (note == null) ou remplace le fichier d'une note
  /// existante (note != null). Demande d'abord un semestre optionnel, puis
  /// laisse l'utilisateur choisir un fichier (PDF ou Image).
  Future<void> _pickAndUploadNote({Map<String, dynamic>? note}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null) return;
    if (!mounted) return;

    final semestreCtrl =
        TextEditingController(text: note?['semestre']?.toString() ?? '');
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null
            ? 'Ajouter une note (PDF ou Image)'
            : "Remplacer le fichier de la note"),
        content: TextField(
          controller: semestreCtrl,
          decoration: const InputDecoration(labelText: 'Semestre (optionnel)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _uploadingNoteId = note?['id']?.toString() ?? '_new');
    try {
      // 1. Demande d'une URL signée pour l'upload du fichier de note.
      final uploadInfo = await _api.post('/profils/moi/notes/upload-url', {
        'nom_fichier': file.name,
      });
      final uploadUrl = uploadInfo['upload_url'] as String;

      // 2. Envoi du fichier directement vers l'URL signée.
      String contentType = 'application/octet-stream';
      final fileNameLower = file.name.toLowerCase();
      if (fileNameLower.endsWith('.pdf')) {
        contentType = 'application/pdf';
      } else if (fileNameLower.endsWith('.png')) {
        contentType = 'image/png';
      } else if (fileNameLower.endsWith('.jpg') ||
          fileNameLower.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }

      final putResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: file.bytes,
      );
      if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
        throw Exception(
            "Échec de l'upload du fichier (${putResponse.statusCode})");
      }

      final semestre =
          semestreCtrl.text.trim().isEmpty ? null : semestreCtrl.text.trim();

      // 3. Confirmation côté API.
      if (note == null) {
        await _api.post('/profils/moi/notes/confirmer', {
          'cle_fichier': uploadInfo['cle_fichier'],
          'nom_fichier': file.name,
          'semestre': semestre,
        });
      } else {
        await _api.put('/profils/moi/notes/${note['id']}', {
          'cle_fichier': uploadInfo['cle_fichier'],
          'nom_fichier': file.name,
          'semestre': semestre,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(note == null ? 'Note ajoutée.' : 'Note mise à jour.')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'envoi de la note : $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingNoteId = null);
    }
  }

  /// Modifie uniquement le libellé "semestre" d'une note, sans toucher à
  /// l'image déjà uploadée.
  Future<void> _editNoteSemestre(Map<String, dynamic> note) async {
    final semestreCtrl =
        TextEditingController(text: note['semestre']?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le semestre'),
        content: TextField(
          controller: semestreCtrl,
          decoration: const InputDecoration(labelText: 'Semestre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (saved != true) return;

    try {
      await _api.put('/profils/moi/notes/${note['id']}', {
        'semestre':
            semestreCtrl.text.trim().isEmpty ? null : semestreCtrl.text.trim(),
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
        );
      }
    }
  }

  Future<void> _removeNote(dynamic noteId) async {
    if (noteId == null) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note'),
        content: const Text('Voulez-vous vraiment supprimer cette note ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    try {
      await _api.delete('/profils/moi/notes/$noteId');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la suppression de la note : $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Photo de profil
  // ---------------------------------------------------------------------

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      // 1. Demande d'une URL signée pour l'upload de la photo.
      final uploadInfo = await _api.post('/profils/moi/photo/upload-url', {
        'nom_fichier': image.name,
      });
      final uploadUrl = uploadInfo['upload_url'] as String;

      // 2. Envoi du fichier directement vers l'URL signée.
      // On utilise XFile.readAsBytes() (et non dart:io File) pour rester
      // compatible avec Flutter Web, où dart:io n'est pas disponible.
      final bytes = await image.readAsBytes();
      final putResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: bytes,
      );
      if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
        throw Exception(
            'Échec de l\'upload de la photo (${putResponse.statusCode})');
      }

      // 3. Confirmation côté API pour rattacher la photo au profil.
      await _api.post('/profils/moi/photo/confirmer', {
        'cle_fichier': uploadInfo['cle_fichier'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour.')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'upload de la photo : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ---------------------------------------------------------------------
  // CV
  // ---------------------------------------------------------------------

  Future<void> _pickAndUploadCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null) return;

    setState(() => _uploadingCv = true);
    try {
      // 1. Demande d'une URL signée pour l'upload du CV.
      final uploadInfo = await _api.post('/profils/moi/cv/upload-url', {
        'nom_fichier': file.name,
      });
      final uploadUrl = uploadInfo['upload_url'] as String;

      // 2. Envoi du fichier directement vers l'URL signée.
      final contentType = file.name.toLowerCase().endsWith('.pdf')
          ? 'application/pdf'
          : 'application/octet-stream';
      final putResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: file.bytes,
      );
      if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
        throw Exception('Échec de l\'upload du CV (${putResponse.statusCode})');
      }

      // 3. Confirmation côté API pour rattacher le CV au profil.
      await _api.post('/profils/moi/cv/confirmer', {
        'cle_fichier': uploadInfo['cle_fichier'],
        'nom_fichier': file.name,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV téléversé avec succès.')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'upload du CV : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingCv = false);
    }
  }

  // ---------------------------------------------------------------------
  // Modifier filière / spécialité / niveau
  // ---------------------------------------------------------------------

  /// Retourne le libellé lisible ("Licence 1") pour une valeur d'enum
  /// stockée en base ("I", "II", "III").
  String _libelleNiveau(String niveau) {
    switch (niveau) {
      case 'I':
        return 'Licence 1';
      case 'II':
        return 'Licence 2';
      case 'III':
        return 'Licence 3';
      default:
        return niveau;
    }
  }

  Future<void> _openEditDialog(Map<String, dynamic>? etudiant) async {
    final prenomCtrl = TextEditingController(text: etudiant?['prenom'] ?? '');
    final nomCtrl = TextEditingController(text: etudiant?['nom'] ?? '');
    final filiereCtrl = TextEditingController(text: etudiant?['filiere'] ?? '');
    final specialiteCtrl =
        TextEditingController(text: etudiant?['specialite'] ?? '');

    // Sécurise la valeur initiale : si le niveau stocké n'est pas l'une des
    // valeurs valides de l'enum (ex: null, "L1", valeur legacy...), on
    // retombe sur 'I' pour éviter le crash du DropdownButtonFormField.
    final niveauInitial = etudiant?['niveau'];
    String niveau =
        _niveauxValides.contains(niveauInitial) ? niveauInitial as String : 'I';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier mes informations'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: prenomCtrl,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                    ),
                    TextField(
                      controller: nomCtrl,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    TextField(
                      controller: filiereCtrl,
                      decoration: const InputDecoration(labelText: 'Filière'),
                    ),
                    TextField(
                      controller: specialiteCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Spécialité'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: niveau,
                      decoration: const InputDecoration(labelText: 'Niveau'),
                      items: [
                        for (final n in _niveauxValides)
                          DropdownMenuItem(
                              value: n, child: Text(_libelleNiveau(n))),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => niveau = v ?? niveau),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        await _api.put('/profils/moi', {
          'prenom': prenomCtrl.text.trim(),
          'nom': nomCtrl.text.trim(),
          'filiere': filiereCtrl.text.trim(),
          'specialite': specialiteCtrl.text.trim(),
          'niveau': niveau,
        });
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
          );
        }
      }
    }
  }

  Future<void> _requestPasswordReset() async {
    final email = context.read<AuthProvider>().user?.email;
    if (email == null || email.isEmpty) return;
    try {
      await context.read<AuthProvider>().demanderReinitialisationMotDePasse(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Un code de réinitialisation a été envoyé par email.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de modifier le mot de passe : $e')),
      );
    }
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Erreur: $_error'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final etudiant = _profil?['etudiant'] as Map<String, dynamic>?;
    final competences = (_profil?['competences'] as List?) ?? [];
    final interets = (_profil?['interets'] as List?) ?? [];
    final cv = _profil?['cv'] as Map<String, dynamic>?;
    final photoUrl = etudiant?['photo_url'] as String?;
    final niveauAffiche = etudiant?['niveau'] != null
        ? _libelleNiveau(etudiant!['niveau'] as String)
        : 'non renseigné';
    final email = context.read<AuthProvider>().user?.email ?? 'Email non renseigné';

    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.cardGrey,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person,
                                size: 34, color: AppColors.textMuted)
                            : null,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: InkWell(
                          onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.darkGreen,
                              shape: BoxShape.circle,
                            ),
                            child: _uploadingPhoto
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt,
                                    size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${etudiant?['prenom'] ?? ''} ${etudiant?['nom'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          etudiant?['filiere'] != null &&
                                  (etudiant?['filiere'] as String).isNotEmpty
                              ? etudiant!['filiere']
                              : 'Filière non renseignée',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                        Text(
                          etudiant?['specialite'] != null &&
                                  (etudiant?['specialite'] as String).isNotEmpty
                              ? etudiant!['specialite']
                              : 'Spécialité non renseignée',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                        Text(
                          'Niveau: $niveauAffiche',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.darkGreen),
                    onPressed: () => _openEditDialog(etudiant),
                    tooltip: 'Modifier mes informations',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _profilePanel(
                title: 'Compte et sécurité',
                icon: Icons.shield_outlined,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined, color: AppColors.darkGreen),
                      title: const Text('Adresse email', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      subtitle: Text(email, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline, color: AppColors.darkGreen),
                      title: const Text('Mot de passe', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      subtitle: const Text('••••••••', style: TextStyle(letterSpacing: 2, color: AppColors.textDark)),
                      trailing: TextButton(
                        onPressed: _requestPasswordReset,
                        child: const Text('Modifier'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _profilePanel(
                title: 'Compétences',
                icon: Icons.code_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in competences)
                    Chip(
                      label: Text('${c['competence_nom']} (${c['niveau']})'),
                      onDeleted: () => _removeCompetence(c['id']),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _competenceCtrl,
                      decoration:
                          const InputDecoration(hintText: 'Ex: Flutter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _niveauCompetence,
                    items: const [
                      DropdownMenuItem(
                          value: 'debutant', child: Text('Débutant')),
                      DropdownMenuItem(
                          value: 'intermediaire', child: Text('Intermédiaire')),
                      DropdownMenuItem(value: 'avance', child: Text('Avancé')),
                    ],
                    onChanged: (v) =>
                        setState(() => _niveauCompetence = v ?? 'debutant'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: AppColors.darkGreen),
                    onPressed: _addCompetence,
                  ),
                ],
              ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _profilePanel(
                title: "Centres d'intérêt",
                icon: Icons.favorite_border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final i in interets)
                    Chip(
                      label: Text('${i['domaine']}'),
                      onDeleted: () => _removeInteret(i['id']),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _interetCtrl,
                      decoration: const InputDecoration(
                          hintText: 'Ex: Intelligence artificielle'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: AppColors.darkGreen),
                    onPressed: _addInteret,
                  ),
                ],
              ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _profilePanel(
                title: 'CV professionnel',
                icon: Icons.description_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              if (cv != null && cv['nom_fichier'] != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description,
                        color: AppColors.darkGreen),
                    title: Text(cv['nom_fichier']),
                    subtitle: const Text('CV actuel'),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Remplacer',
                      onPressed: _uploadingCv ? null : _pickAndUploadCv,
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _uploadingCv ? null : _pickAndUploadCv,
                  icon: _uploadingCv
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                      _uploadingCv ? 'Envoi en cours...' : 'Uploader mon CV'),
                ),
                ],
              ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Mes notes'),
                  IconButton(
                    icon: _uploadingNoteId == '_new'
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle,
                            color: AppColors.darkGreen),
                    tooltip: 'Ajouter une note (PDF ou image)',
                    onPressed: _uploadingNoteId != null
                        ? null
                        : () => _pickAndUploadNote(),
                  ),
                ],
              ),
              if (_notes.isEmpty)
                const Text(
                  'Aucune note enregistrée pour le moment.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                )
              else
                Column(
                  children: [
                    for (final n in _notes)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: (n['nom_fichier']
                                        ?.toString()
                                        .toLowerCase()
                                        .endsWith('.pdf') ??
                                    false)
                                ? Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColors.errorBackground,
                                    child: const Icon(Icons.picture_as_pdf,
                                        color: AppColors.error, size: 24),
                                  )
                                : Image.network(
                                    n['url'] ?? '',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                          ),
                          title: Text(
                            n['semestre'] != null &&
                                    (n['semestre'] as String).isNotEmpty
                                ? 'Semestre: ${n['semestre']}'
                                : 'Note',
                          ),
                          subtitle: Text(n['nom_fichier']?.toString() ?? ''),
                          trailing: (_uploadingNoteId == n['id']?.toString())
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      tooltip: 'Modifier le semestre',
                                      onPressed: () => _editNoteSemestre(n),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.refresh, size: 20),
                                      tooltip: "Remplacer le fichier",
                                      onPressed: _uploadingNoteId != null
                                          ? null
                                          : () => _pickAndUploadNote(note: n),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 20, color: Colors.redAccent),
                                      tooltip: 'Supprimer',
                                      onPressed: () => _removeNote(n['id']),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                  ],
                ),
              if (_loadingRecommandations || _recommandations.isNotEmpty) ...[
                const SizedBox(height: 28),
                _sectionTitle('Recommandations personnalisées'),
                if (_loadingRecommandations)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      for (final r in _recommandations)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(_iconForType(r['type']),
                                color: AppColors.darkGreen),
                            title: Text(r['titre'] ?? ''),
                            subtitle: Text(r['type'] ?? ''),
                          ),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'specialite':
        return Icons.school;
      case 'technologie':
        return Icons.code;
      case 'certification':
        return Icons.workspace_premium;
      case 'formation':
        return Icons.menu_book;
      case 'metier':
        return Icons.work;
      default:
        return Icons.recommend;
    }
  }

  Widget _profilePanel({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardGrey.withOpacity(0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: AppColors.darkGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGreen,
          ),
        ),
      );
}
