import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iexajsvuvicpsooqeljb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlleGFqc3Z1dmljcHNvb3FlbGpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUzMDMxMjAsImV4cCI6MjA2MDg3OTEyMH0.umbdPpKZLwL6DYaEPlTrarCrh60dJh8qHt5iZXQifSo',
  );

  runApp(const ApplicationPrincipale());
}

final supabase = Supabase.instance.client;

class ApplicationPrincipale extends StatelessWidget {
  const ApplicationPrincipale({super.key});

  @override
  Widget build(BuildContext contexte) {
    return MaterialApp(
      title: 'Notes Supabase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      home: const PageDesNotes(),
    );
  }
}

class PageDesNotes extends StatefulWidget {
  const PageDesNotes({super.key});

  @override
  State<PageDesNotes> createState() => _EtatPageDesNotes();
}

class _EtatPageDesNotes extends State<PageDesNotes> {
  List<dynamic> listeNotes = [];
  bool estEnChargement = false;

  @override
  void initState() {
    super.initState();
    chargerNotes();
  }

  Future<void> chargerNotes() async {
    setState(() => estEnChargement = true);
    final reponse = await supabase.from('note').select().order('id', ascending: false);
    setState(() {
      listeNotes = reponse;
      estEnChargement = false;
    });
  }

  Future<void> supprimerNote(int id) async {
    setState(() => estEnChargement = true);
    await supabase.from('note').delete().eq('id', id);
    await chargerNotes();
  }

  Future<void> modifierNote(int id, String texte) async {
    setState(() => estEnChargement = true);
    await supabase.from('note').update({'text': texte}).eq('id', id);
    await chargerNotes();
  }

  Future<void> ajouterNote(String texte) async {
    setState(() => estEnChargement = true);
    await supabase.from('note').insert({'text': texte});
    await chargerNotes();
  }

  void afficherDialogueNote({String? texteActuel, int? idNote}) {
    final controleurTexte = TextEditingController(text: texteActuel);
    final estEdition = texteActuel != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(
          estEdition ? 'Modifier la note' : 'Ajouter une note',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controleurTexte,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Texte',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            border: OutlineInputBorder(),
          ),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              final texte = controleurTexte.text.trim();
              if (texte.isNotEmpty) {
                estEdition ? modifierNote(idNote!, texte) : ajouterNote(texte);
              }
              Navigator.of(context).pop();
            },
            child: Text(
              estEdition ? 'Enregistrer' : 'Ajouter',
              style: const TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  String formaterDate(String? dateIso) {
    if (dateIso == null) return '';
    final date = DateTime.tryParse(dateIso)?.toLocal();
    if (date == null) return '';

    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final annee = date.year;
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$jour/$mois/$annee à $heure:$minute';
  }

  @override
  Widget build(BuildContext contexte) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Notes'),
      ),
      body: estEnChargement
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vos notes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: listeNotes.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucune note pour le moment.',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: listeNotes.length,
                            itemBuilder: (contexte, index) {
                              final note = listeNotes[index];
                              final texteNote = note['text'] ?? 'Aucun texte';
                              final dateNote = formaterDate(note['created_at']);

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                                    ),
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    child: ListTile(
                                      title: Text(
                                        texteNote,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: dateNote.isNotEmpty
                                          ? Text(
                                              'Créée le $dateNote',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                            )
                                          : null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.white),
                                            onPressed: () => afficherDialogueNote(
                                              texteActuel: texteNote,
                                              idNote: note['id'],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                                            onPressed: () => supprimerNote(note['id']),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => afficherDialogueNote(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
