import 'package:flutter/material.dart';
import 'package:my_notebook/services/auth/auth_service.dart';
import 'package:my_notebook/services/auth/crud/notes_service.dart';
import 'package:my_notebook/utilities/generics/get_arguments.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}



class _NewNoteViewState extends State<NewNoteView> {
  DatabaseNote? _note;
  late final NoteService _notesService;
  late final TextEditingController _textController;
   
  
  @override
  void initState() {
    _notesService = NoteService();
    _textController = TextEditingController();
    super.initState();
  }


  Future<DatabaseNote> createOrGetExistingNote(BuildContext context) async {

    final widgetNote = context.getargument<DatabaseNote>();

    if (widgetNote != null){
      _note = widgetNote;
      _textController.text = widgetNote.text;
      return widgetNote;
    }




    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner  = await _notesService.getUser(email: email);
    final newNote = await _notesService.createNote(owner : owner);
    _note = newNote;
    return newNote;
    
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (note != null && text.isNotEmpty) {
      await _notesService.updateNote(
        note: note,
        text: text,
      );
    }
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  void _textControllerListener() {
    setState(() {});
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: FutureBuilder(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start typing your note..',
                ),
              );
            default: return const CircularProgressIndicator();
          }
        }
      ) 
    
    );
  }
}



