import unittest

from src.db.backend.memory import LessonDatabase, LessonRecord


class LessonDatabaseTest(unittest.TestCase):
    def setUp(self) -> None:
        self.database = LessonDatabase()

    def test_create_record_adds_lesson(self) -> None:
        record = self.database.create_record(
            1,
            " Анна ",
            " математика ",
            "25.04.2026",
            1200,
        )

        self.assertEqual(
            record,
            LessonRecord(1, "Анна", "математика", "25.04.2026", 1200),
        )
        self.assertEqual(self.database.select_record(), [record])

    def test_create_record_rejects_invalid_values(self) -> None:
        invalid_cases = [
            (0, "Анна", "математика", "25.04.2026", 1200),
            (1, "", "математика", "25.04.2026", 1200),
            (1, "Анна", "", "25.04.2026", 1200),
            (1, "Анна", "математика", "", 1200),
            (1, "Анна", "математика", "25.04.2026", -1),
        ]

        for case in invalid_cases:
            with self.subTest(case=case):
                with self.assertRaises(ValueError):
                    self.database.create_record(*case)

    def test_create_record_rejects_duplicate_id(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)

        with self.assertRaises(ValueError):
            self.database.create_record(1, "Иван", "физика", "26.04.2026", 1500)

    def test_select_record_filters_by_fields(self) -> None:
        first = self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        self.database.create_record(2, "Иван", "физика", "26.04.2026", 1500)

        self.assertEqual(self.database.select_record(student_name="анна"), [first])
        self.assertEqual(self.database.select_record(subject="МАТЕМАТИКА"), [first])
        self.assertEqual(self.database.select_record(lesson_date="25.04.2026"), [first])
        self.assertEqual(self.database.select_record(price=1200), [first])
        self.assertEqual(self.database.select_record(lesson_id=1), [first])

    def test_update_record_changes_selected_fields(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)

        record = self.database.update_record(1, subject="физика", price=1500)

        self.assertEqual(record.subject, "физика")
        self.assertEqual(record.price, 1500)
        self.assertEqual(record.student_name, "Анна")

    def test_update_record_rejects_missing_id_and_invalid_values(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)

        with self.assertRaises(ValueError):
            self.database.update_record(2, subject="физика")

        with self.assertRaises(ValueError):
            self.database.update_record(1, student_name="")

        with self.assertRaises(ValueError):
            self.database.update_record(1, price=-10)

    def test_delete_record_removes_lesson(self) -> None:
        record = self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)

        deleted = self.database.delete_record(1)

        self.assertEqual(deleted, record)
        self.assertEqual(self.database.select_record(), [])

    def test_delete_record_rejects_missing_id(self) -> None:
        with self.assertRaises(ValueError):
            self.database.delete_record(1)

    def test_sort_records_by_selected_field(self) -> None:
        second = self.database.create_record(2, "Иван", "физика", "26.04.2026", 1500)
        first = self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)

        self.assertEqual(self.database.sort_records("id"), [first, second])
        self.assertEqual(self.database.sort_records("price", descending=True), [second, first])

    def test_sort_records_rejects_unknown_field(self) -> None:
        with self.assertRaises(ValueError):
            self.database.sort_records("unknown")

    def test_init_accepts_valid_initial_records(self) -> None:
        initial = [
            LessonRecord(1, " Анна ", " математика ", "25.04.2026", 1200),
            LessonRecord(2, "Иван", "физика", "26.04.2026", 1500),
        ]

        database = LessonDatabase(initial)

        self.assertEqual(
            database.select_record(),
            [
                LessonRecord(1, "Анна", "математика", "25.04.2026", 1200),
                LessonRecord(2, "Иван", "физика", "26.04.2026", 1500),
            ],
        )

    def test_init_validates_initial_records(self) -> None:
        invalid_cases = [
            [LessonRecord(0, "Анна", "математика", "25.04.2026", 1200)],
            [LessonRecord(1, "", "математика", "25.04.2026", 1200)],
            [LessonRecord(1, "Анна", "математика", "25.04.2026", -1)],
        ]

        for case in invalid_cases:
            with self.subTest(case=case):
                with self.assertRaises(ValueError):
                    LessonDatabase(case)

    def test_init_rejects_duplicate_id_in_initial_records(self) -> None:
        duplicated = [
            LessonRecord(1, "Анна", "математика", "25.04.2026", 1200),
            LessonRecord(1, "Иван", "физика", "26.04.2026", 1500),
        ]

        with self.assertRaises(ValueError):
            LessonDatabase(duplicated)

    def test_init_with_no_records_creates_empty_database(self) -> None:
        database = LessonDatabase()

        self.assertEqual(database.select_record(), [])


if __name__ == "__main__":
    unittest.main()
