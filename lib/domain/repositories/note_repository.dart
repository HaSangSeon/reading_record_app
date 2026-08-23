import '../../data/models/note_model.dart';

/// 독서 노트 데이터에 대한 CRUD 및 스트림 조회를 정의하는 추상 인터페이스
abstract class NoteRepository {
  /// 모든 독서 노트 목록 조회
  Future<List<Note>> getAllNotes();

  /// 특정 책(bookId)에 속한 모든 독서 노트 조회 (페이지 순/생성순 정렬)
  Future<List<Note>> getNotesByBookId(String bookId);

  /// 특정 ID의 독서 노트 조회
  Future<Note?> getNoteById(String id);

  /// 새 독서 노트 추가
  Future<void> addNote(Note note);

  /// 기존 독서 노트 수정
  Future<void> updateNote(Note note);

  /// 특정 독서 노트 삭제
  Future<void> deleteNote(String id);

  /// 특정 책에 속한 모든 노트 일괄 삭제
  Future<void> deleteNotesByBookId(String bookId);

  /// 전체 노트 변경사항 실시간 감지 스트림
  Stream<List<Note>> watchAllNotes();

  /// 특정 책의 노트 변경사항 실시간 감지 스트림
  Stream<List<Note>> watchNotesByBookId(String bookId);
}
