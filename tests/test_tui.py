import unittest

from src.db.backend.memory import LessonDatabase
from src.db.tui import LessonTUI


class LessonTUITest(unittest.TestCase):
    def setUp(self) -> None:
        self.database = LessonDatabase()
        self.output: list[str] = []

    def _make_tui(self, answers: list[str]) -> LessonTUI:
        iterator = iter(answers)
        return LessonTUI(
            self.database,
            input_func=lambda _prompt: next(iterator),
            output_func=self.output.append,
        )

    def test_run_adds_and_prints_lesson(self) -> None:
        tui = self._make_tui(["1", "1", "Анна", "математика", "25.04.2026", "1200", "0"])

        tui.run()

        self.assertEqual(len(self.database.select_record()), 1)
        self.assertTrue(any("Занятие добавлено" in line for line in self.output))
        self.assertTrue(any("Анна" in line for line in self.output))

    def test_run_handles_invalid_menu_command(self) -> None:
        tui = self._make_tui(["wrong", "0"])

        tui.run()

        self.assertIn("Неизвестная команда.", self.output)

    def test_find_lessons_prints_matching_record(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        self.database.create_record(2, "Иван", "физика", "26.04.2026", 1500)
        tui = self._make_tui(["3", "", "Анна", "", "", "", "0"])

        tui.run()

        self.assertTrue(any("Анна" in line for line in self.output))
        self.assertFalse(any("Иван, предмет: физика" in line for line in self.output))

    def test_update_lesson_changes_record(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        tui = self._make_tui(["4", "1", "", "физика", "", "1500", "0"])

        tui.run()

        record = self.database.select_record(lesson_id=1)[0]
        self.assertEqual(record.subject, "физика")
        self.assertEqual(record.price, 1500)

    def test_delete_lesson_removes_record(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        tui = self._make_tui(["5", "1", "0"])

        tui.run()

        self.assertEqual(self.database.select_record(), [])
        self.assertTrue(any("Удалена запись" in line for line in self.output))

    def test_sort_lesson_prints_records_in_selected_order(self) -> None:
        self.database.create_record(1, "Анна", "математика", "25.04.2026", 1200)
        self.database.create_record(2, "Иван", "физика", "26.04.2026", 1500)
        tui = self._make_tui(["6", "price", "desc", "0"])

        tui.run()

        printed_records = [line for line in self.output if "Ученик:" in line]
        self.assertTrue(printed_records[0].startswith("2."))
        self.assertTrue(printed_records[1].startswith("1."))

    def test_read_int_repeats_until_valid_input(self) -> None:
        tui = self._make_tui(["text", "7"])

        self.assertEqual(tui._read_int("id: "), 7)
        self.assertIn("Ошибка: введите целое число.", self.output)

    def test_sort_lesson_prints_error_for_unknown_field(self) -> None:
        tui = self._make_tui(["6", "unknown", "asc", "0"])

        tui.run()

        self.assertTrue(any(line.startswith("Ошибка:") for line in self.output))


if __name__ == "__main__":
    unittest.main()
