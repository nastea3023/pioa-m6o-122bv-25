"""Тесты для файловой СУБД StudentTableFileStorage."""

import json
import os
import tempfile
import unittest

from lab_04.src.db.backend.file_storage import StudentTableFileStorage
from lab_04.src.db.backend.errors import (
    DuplicateIDError,
    InvalidAgeError,
)


class TestFileStorage(unittest.TestCase):

    def setUp(self) -> None:
        self._temp_file = tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        )
        self._temp_file.close()
        self.file_path: str = self._temp_file.name
        self.storage = StudentTableFileStorage(self.file_path)

    def tearDown(self) -> None:
        if os.path.exists(self.file_path):
            os.remove(self.file_path)

    # --- Создание записи ---

    def test_create_record(self) -> None:
        test_data = (1, "John", "Doe", 20, "M")
        record = self.storage.create_record(*test_data)
        self.assertEqual(record, test_data)

    def test_create_record_multiple(self) -> None:
        cases = [
            (1, "John", "Doe", 20, "M"),
            (2, "Jane", "Smith", 22, "F"),
            (3, "Alice", "Johnson", 19, "F"),
        ]
        for test_data in cases:
            with self.subTest(test_data=test_data):
                record = self.storage.create_record(*test_data)
                self.assertEqual(record, test_data)

    def test_create_record_strips_whitespace(self) -> None:
        record = self.storage.create_record(1, "  John  ", "  Doe  ", 20, "  M  ")
        self.assertEqual(record, (1, "John", "Doe", 20, "M"))

    # --- Исключения ---

    def test_create_record_negative_age(self) -> None:
        with self.assertRaises(InvalidAgeError) as context:
            self.storage.create_record(1, "John", "Doe", -5, "M")
        self.assertEqual(
            str(context.exception), "Поле age не может быть отрицательным."
        )

    def test_create_record_duplicate_id(self) -> None:
        self.storage.create_record(1, "John", "Doe", 20, "M")
        with self.assertRaises(DuplicateIDError) as context:
            self.storage.create_record(1, "Jane", "Smith", 22, "F")
        self.assertEqual(
            str(context.exception), "Запись с id=1 уже существует."
        )

    # --- Сохранение в файл ---

    def test_save_creates_file(self) -> None:
        self.storage.create_record(1, "John", "Doe", 20, "M")
        self.assertTrue(os.path.exists(self.file_path))

    def test_save_structure(self) -> None:
        self.storage.create_record(1, "John", "Doe", 20, "M")
        with open(self.file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        self.assertIn("structure", data)
        self.assertIn("records", data)
        self.assertEqual(data["structure"]["student_id"], "int")

    def test_save_records(self) -> None:
        test_data = (1, "John", "Doe", 20, "M")
        self.storage.create_record(*test_data)
        with open(self.file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        self.assertEqual(data["records"], [list(test_data)])

    # --- Загрузка из файла ---

    def test_load_existing_file(self) -> None:
        test_data = (1, "John", "Doe", 20, "M")
        self.storage.create_record(*test_data)
        new_storage = StudentTableFileStorage(self.file_path)
        self.assertEqual(new_storage.select_record(), [test_data])

    def test_load_nonexistent_file(self) -> None:
        os.remove(self.file_path)
        storage = StudentTableFileStorage(self.file_path)
        self.assertEqual(storage.select_record(), [])

    def test_load_corrupted_file(self) -> None:
        with open(self.file_path, "w", encoding="utf-8") as f:
            f.write("{ invalid json ")
        storage = StudentTableFileStorage(self.file_path)
        self.assertEqual(storage.select_record(), [])

    # --- Выборка ---

    def test_select_record_by_id(self) -> None:
        self.storage.create_record(1, "John", "Doe", 20, "M")
        self.storage.create_record(2, "Jane", "Smith", 22, "F")
        result = self.storage.select_record(student_id=2)
        self.assertEqual(result, [(2, "Jane", "Smith", 22, "F")])

    def test_select_record_by_sex(self) -> None:
        self.storage.create_record(1, "John", "Doe", 20, "M")
        self.storage.create_record(2, "Jane", "Smith", 22, "F")
        result = self.storage.select_record(sex="F")
        self.assertEqual(result, [(2, "Jane", "Smith", 22, "F")])

    # --- Структура и очистка ---

    def test_get_structure(self) -> None:
        structure = self.storage.get_structure()
        self.assertIn("student_id", structure)
        self.assertIn("first_name", structure)
        self.assertIn("age", structure)

    def test_clear(self) -> None:
        self.storage.create_record(1, "John", "Doe", 20, "M")
        self.storage.clear()
        self.assertEqual(len(self.storage), 0)

    def test_len(self) -> None:
        self.assertEqual(len(self.storage), 0)
        self.storage.create_record(1, "John", "Doe", 20, "M")
        self.assertEqual(len(self.storage), 1)


if __name__ == "__main__":
    unittest.main()