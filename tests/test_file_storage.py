"""Tests for the file-based lessons database."""

import os
import tempfile
import unittest

from src.db.backend.file_storage import FileLessonDatabase
from src.db.backend.memory import LessonRecord


class FileLessonDatabaseTest(unittest.TestCase):

    def setUp(self) -> None:
        # Временный файл для каждого теста

        self._temp = tempfile.NamedTemporaryFile(  # noqa: SIM115
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        )
        self._temp.close()
        self.file_path = self._temp.name
        self.database = FileLessonDatabase(self.file_path)

    def tearDown(self) -> None:
        if os.path.exists(self.file_path):
            os.remove(self.file_path)

    # ------------------------------------------------------------------
    # Создание
    # ------------------------------------------------------------------

    def test_create_record_adds_lesson(self) -> None:
        record = self.database.create_record(
            1, " Анна ", " математика ", "25.04.2026", 1200
        )
        self.assertEqual(
            record,
            LessonRecord(1, "Анна", "математика", "25.04.2026", 1200),
        )
        self.assertEqual(self.database.select_record(), [record])

    def test_create_record_saves_to_file(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        # Перезагружаем из файла
        new_db = FileLessonDatabase(self.file_path)
        records = new_db.select_record()
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0].student_name, "Анна")

    def test_create_record_rejects_invalid_values(self) -> None:
        invalid_cases = [
            (0, "Анна", "математика", "25.04.2026", 1200),
            (1, "", "математика", "25.04.2026", 1200),
            (1, "Анна", "", "25.04.2026", 1200),
            (1, "Анна", "математика", "", 1200),
            (1, "Анна", "математика", "25.04.2026", -1),
        ]
        for case in invalid_cases:
            with self.subTest(case=case), self.assertRaises(ValueError):
                self.database.create_record(*case)

    def test_create_record_rejects_duplicate_id(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        with self.assertRaises(ValueError):
            self.database.create_record(1, "Иван", "физика", "26.04.2026", 1500)

    # ------------------------------------------------------------------
    # Выборка
    # ------------------------------------------------------------------

    def test_select_record_filters_by_fields(self) -> None:
        first = self.database.create_record(
            1, "Анна", "математика", "25.04.2026", 1200
        )
        self.database.create_record(2, "Иван", "физика", "26.04.2026", 1500)

        self.assertEqual(self.database.select_record(student_name="анна"), [first])
        self.assertEqual(self.database.select_record(subject="МАТЕМАТИКА"), [first])
        self.assertEqual(self.database.select_record(lesson_date="25.04.2026"), [first])
        self.assertEqual(self.database.select_record(price=1200), [first])
        self.assertEqual(self.database.select_record(lesson_id=1), [first])

    # ------------------------------------------------------------------
    # Обновление
    # ------------------------------------------------------------------

    def test_update_record_changes_selected_fields(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        record = self.database.update_record(1, subject="физика", price=1500)
        self.assertEqual(record.subject, "физика")
        self.assertEqual(record.price, 1500)
        self.assertEqual(record.student_name, "Анна")

    def test_update_record_persists_to_file(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        self.database.update_record(1, price=2000)

        new_db = FileLessonDatabase(self.file_path)
        records = new_db.select_record(lesson_id=1)
        self.assertEqual(records[0].price, 2000)

    def test_update_record_rejects_missing_id_and_invalid_values(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)

        with self.assertRaises(ValueError):
            self.database.update_record(2, subject="физика")
        with self.assertRaises(ValueError):
            self.database.update_record(1, student_name="")
        with self.assertRaises(ValueError):
            self.database.update_record(1, price=-10)

    # ------------------------------------------------------------------
    # Удаление
    # ------------------------------------------------------------------

    def test_delete_record_removes_lesson(self) -> None:
        record = self.database.create_record(
            1, "Анна", "математика", "25.04.2026", 1200
        )
        deleted = self.database.delete_record(1)
        self.assertEqual(deleted, record)
        self.assertEqual(self.database.select_record(), [])

    def test_delete_record_persists_to_file(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        self.database.delete_record(1)

        new_db = FileLessonDatabase(self.file_path)
        self.assertEqual(new_db.select_record(), [])

    def test_delete_record_rejects_missing_id(self) -> None:
        with self.assertRaises(ValueError):
            self.database.delete_record(1)

    # ------------------------------------------------------------------
    # Сортировка
    # ------------------------------------------------------------------

    def test_sort_records_by_selected_field(self) -> None:
        second = self.database.create_record(
            2, "Иван", "физика", "26.04.2026", 1500
        )
        first = self.database.create_record(
            1, "Анна", "математика", "25.04.2026", 1200
        )

        self.assertEqual(self.database.sort_records("id"), [first, second])
        self.assertEqual(
            self.database.sort_records("price", descending=True),
            [second, first],
        )

    def test_sort_records_rejects_unknown_field(self) -> None:
        with self.assertRaises(ValueError):
            self.database.sort_records("unknown")

    # ------------------------------------------------------------------
    # Работа с файлом
    # ------------------------------------------------------------------

    def test_load_from_nonexistent_file(self) -> None:
        os.remove(self.file_path)
        db = FileLessonDatabase(self.file_path)
        self.assertEqual(db.select_record(), [])

    def test_load_corrupted_file(self) -> None:
        with open(self.file_path, "w", encoding="utf-8") as f:
            f.write("{ invalid json ")
        db = FileLessonDatabase(self.file_path)
        self.assertEqual(db.select_record(), [])

    def test_file_contains_structure(self) -> None:
        import json

        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        with open(self.file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        self.assertIn("structure", data)
        self.assertIn("records", data)
        self.assertEqual(data["structure"]["lesson_id"], "int")


if __name__ == "__main__":
    unittest.main()
