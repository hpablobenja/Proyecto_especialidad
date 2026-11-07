filepath = r'c:\Users\BENJAMIN\Documents\Maestria Flutter\redmaestra1\lib\presentation\screens\admin\course_management_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Buscamos la sección de lecciones y cuestionarios
target_old = """        // Guardar en la colección 'lessons' raíz
        final lessonRef = await firestore.collection('lessons').add(lessonData);
        // Actualizar el campo 'id' con el id real de Firestore para consistencia
        await lessonRef.update({'id': lessonRef.id});

        // También registrar en subcolección para queries anidadas
        await firestore
            .collection('courses')
            .doc(realCourseId)
            .collection('modules')
            .doc(realModuleId)
            .collection('lessons')
            .doc(lessonRef.id)
            .set(lessonData);

        if (lessonImport.id.isNotEmpty) {
          lessonIdMap[lessonImport.id.trim()] = lessonRef.id;
        }
      }

      // 5. Procesar Cuestionarios, Preguntas y Respuestas
      if (result.quizzes.isNotEmpty) {
        // Agrupar respuestas por preguntaId
        final answersByQuestion = <String, List<AnswerImportModel>>{};
        for (final ans in result.answers) {
          answersByQuestion.putIfAbsent(ans.questionId.trim(), () => []).add(ans);
        }

        // Agrupar preguntas por quizId
        final questionsByQuiz = <String, List<QuestionImportModel>>{};
        for (final q in result.questions) {
          questionsByQuiz.putIfAbsent(q.quizId.trim(), () => []).add(q);
        }

        for (final quizImport in result.quizzes) {
          final rawLessonId = quizImport.lessonId.trim();
          final realLessonId = lessonIdMap[rawLessonId] ?? rawLessonId;

          // Buscar el curso y módulo de la lección
          String quizCourseId = '';
          String quizModuleId = '';

          final lessonDoc = await firestore.collection('lessons').doc(realLessonId).get();
          if (lessonDoc.exists) {
            quizCourseId = (lessonDoc.data()?['courseId'] as String? ?? '');
            quizModuleId = (lessonDoc.data()?['moduleId'] as String? ?? '');
          }

          final quizQuestionsModels = questionsByQuiz[quizImport.id.trim()] ?? [];
          final questionsEntities = <Map<String, dynamic>>[];

          for (final qModel in quizQuestionsModels) {
            final answers = answersByQuestion[qModel.id.trim()] ?? [];
            final options = <String>[];
            int correctIndex = 0;

            for (int i = 0; i < answers.length; i++) {
              options.add(answers[i].text.trim());
              if (answers[i].isCorrect) {
                correctIndex = i;
              }
            }

            // Asegurar al menos opciones si vinieron menos
            if (options.isEmpty) {
              options.addAll(['Opción 1', 'Opción 2', 'Opción 3']);
            }

            questionsEntities.add({
              'id': qModel.id.isNotEmpty ? qModel.id : DateTime.now().millisecondsSinceEpoch.toString(),
              'text': qModel.text.trim(),
              'options': options,
              'correctAnswerIndex': correctIndex,
            });
          }

          final quizDocRef = firestore.collection('quizzes').doc();
          await quizDocRef.set({
            'id': quizDocRef.id,
            'lessonId': realLessonId,
            'courseId': quizCourseId,
            'moduleId': quizModuleId,
            'title': quizImport.title.isNotEmpty ? quizImport.title.trim() : 'Evaluación',
            'questions': questionsEntities,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }"""

# Versión simplificada para búsqueda robusta
idx1 = text.find("final lessonRef = await firestore.collection('lessons').add(lessonData);")
idx2 = text.find("// Cerrar di", idx1)

if idx1 == -1 or idx2 == -1:
    print(f"Error: indices not found (idx1={idx1}, idx2={idx2})")
    exit(1)

replacement = """final lessonRef = firestore.collection('lessons').doc();
        lessonData['id'] = lessonRef.id;
        await lessonRef.set(lessonData);

        // Subcolección para compatibilidad con queries anidadas
        await firestore
            .collection('courses')
            .doc(realCourseId)
            .collection('modules')
            .doc(realModuleId)
            .collection('lessons')
            .doc(lessonRef.id)
            .set(lessonData);

        if (lessonImport.id.isNotEmpty) {
          lessonIdMap[lessonImport.id.trim()] = lessonRef.id;
        }
      }

      // 5. Procesar Cuestionarios, Preguntas y Respuestas
      if (result.quizzes.isNotEmpty) {
        // Agrupar respuestas por preguntaId
        final answersByQuestion = <String, List<AnswerImportModel>>{};
        for (final ans in result.answers) {
          answersByQuestion.putIfAbsent(ans.questionId.trim(), () => []).add(ans);
        }

        // Agrupar preguntas por quizId
        final questionsByQuiz = <String, List<QuestionImportModel>>{};
        for (final q in result.questions) {
          questionsByQuiz.putIfAbsent(q.quizId.trim(), () => []).add(q);
        }

        for (final quizImport in result.quizzes) {
          final rawLessonId = quizImport.lessonId.trim();
          final realLessonId = lessonIdMap[rawLessonId] ?? rawLessonId;

          // Obtener courseId y moduleId directamente de la lección importada en memoria
          String quizCourseId = '';
          String quizModuleId = '';

          final matchedLesson = result.lessons.firstWhere(
            (l) => l.id.trim() == rawLessonId,
            orElse: () => LessonImportModel(
              id: '',
              courseId: '',
              moduleId: '',
              title: '',
              orderIndex: 0,
            ),
          );

          if (matchedLesson.id.isNotEmpty) {
            final rawCourse = matchedLesson.courseId.trim();
            final rawMod = matchedLesson.moduleId.trim();
            quizCourseId = courseIdMap[rawCourse] ?? defaultCourseFirestoreId ?? rawCourse;
            quizModuleId = moduleIdMap[rawMod] ?? defaultModuleFirestoreId ?? rawMod;
          } else {
            // Si no se encontró en memoria, consultar Firestore como fallback
            try {
              final lessonDoc = await firestore.collection('lessons').doc(realLessonId).get();
              if (lessonDoc.exists) {
                quizCourseId = (lessonDoc.data()?['courseId'] as String? ?? '');
                quizModuleId = (lessonDoc.data()?['moduleId'] as String? ?? '');
              }
            } catch (_) {}
          }

          // Fallback a IDs por defecto si estuvieran vacíos
          if (quizCourseId.isEmpty) {
            quizCourseId = defaultCourseFirestoreId ?? '';
          }
          if (quizModuleId.isEmpty) {
            quizModuleId = defaultModuleFirestoreId ?? '';
          }

          final quizQuestionsModels = questionsByQuiz[quizImport.id.trim()] ?? [];
          final questionsEntities = <Map<String, dynamic>>[];

          for (final qModel in quizQuestionsModels) {
            final answers = answersByQuestion[qModel.id.trim()] ?? [];
            final options = <String>[];
            int correctIndex = 0;

            for (int i = 0; i < answers.length; i++) {
              options.add(answers[i].text.trim());
              if (answers[i].isCorrect) {
                correctIndex = i;
              }
            }

            if (options.isEmpty) {
              options.addAll(['Opción 1', 'Opción 2', 'Opción 3']);
            }

            questionsEntities.add({
              'id': qModel.id.isNotEmpty ? qModel.id : DateTime.now().millisecondsSinceEpoch.toString(),
              'text': qModel.text.trim(),
              'options': options,
              'correctAnswerIndex': correctIndex,
            });
          }

          // Según firestore.rules para /quizzes/{quizId}:
          // request.resource.data.keys().hasAll(['lessonId', 'courseId', 'moduleId'])
          final quizDocRef = firestore.collection('quizzes').doc();
          await quizDocRef.set({
            'id': quizDocRef.id,
            'lessonId': realLessonId,
            'courseId': quizCourseId,
            'moduleId': quizModuleId,
            'questions': questionsEntities,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      """

text = text[:idx1] + replacement + text[idx2:]

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

print('Update successful!')

