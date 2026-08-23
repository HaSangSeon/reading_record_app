import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_record_app/data/models/book_model.dart';
import 'package:reading_record_app/data/models/book_search_result.dart';
import 'package:reading_record_app/data/models/note_model.dart';

void main() {
  group('Model & Backup Unit Tests', () {
    test('Book model creation and progress calculation', () {
      final book = Book(
        id: 'book-1',
        title: '클린 코드',
        author: '로버트 C. 마틴',
        publisher: '인사이트',
        totalPages: 400,
        readPages: 200,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(book.progress, 0.5);
      expect(book.progressPercentage, 50);
      expect(book.isCompleted, false);

      final updatedBook = book.copyWith(readPages: 400, isCompleted: true);
      expect(updatedBook.progress, 1.0);
      expect(updatedBook.progressPercentage, 100);
      expect(updatedBook.isCompleted, true);
    });

    test('Note model creation and serialization', () {
      final now = DateTime(2026, 1, 1);
      final note = Note(
        id: 'note-1',
        bookId: 'book-1',
        pageNumber: 42,
        content: '깨끗한 코드는 읽기 쉽고 명확하다.',
        quotation: '보이스카우트 규칙',
        createdAt: now,
      );

      expect(note.pageNumber, 42);
      expect(note.bookId, 'book-1');

      final map = note.toMap();
      final fromMapNote = Note.fromMap(map);

      expect(fromMapNote.id, note.id);
      expect(fromMapNote.content, note.content);
      expect(fromMapNote.pageNumber, note.pageNumber);
    });

    test('BookSearchResult conversion to Book entity', () {
      const searchResult = BookSearchResult(
        title: '사피엔스',
        author: '유발 하라리',
        publisher: '김영사',
        coverUrl: 'https://example.com/cover.jpg',
        totalPages: 636,
        description: '인류의 역사와 미래',
      );

      final book = searchResult.toBook();
      expect(book.title, '사피엔스');
      expect(book.author, '유발 하라리');
      expect(book.publisher, '김영사');
      expect(book.coverUrl, 'https://example.com/cover.jpg');
      expect(book.totalPages, 636);
      expect(book.memo, '인류의 역사와 미래');
      expect(book.isCompleted, false);
    });

    test('JSON Backup schema serialization test', () {
      final book = Book(
        id: 'b-1',
        title: '데미안',
        author: '헤르만 헤세',
        totalPages: 240,
        createdAt: DateTime(2026, 1, 1),
      );
      final note = Note(
        id: 'n-1',
        bookId: 'b-1',
        pageNumber: 15,
        content: '새는 알을 깨고 나온다.',
        createdAt: DateTime(2026, 1, 1),
      );

      final backup = {
        'app': 'ReadingRecordApp',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'booksCount': 1,
        'notesCount': 1,
        'books': [book.toMap()],
        'notes': [note.toMap()],
      };

      final jsonStr = jsonEncode(backup);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['app'], 'ReadingRecordApp');
      expect(decoded['booksCount'], 1);
      expect((decoded['books'] as List).length, 1);
      expect((decoded['notes'] as List).length, 1);
    });
  });
}
