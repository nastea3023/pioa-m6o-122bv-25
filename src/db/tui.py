"""Console interface for the tutoring lessons database."""

from collections.abc import Callable

from .backend.memory import LessonDatabase, LessonRecord, default_database


class LessonTUI:
    """Text user interface for lesson management."""

    def __init__(
        self,
        database: LessonDatabase | None = None,
        input_func: Callable[[str], str] = input,
        output_func: Callable[[str], None] = print,
    ) -> None:
        self.database = database or default_database
        self.input = input_func
        self.output = output_func

    def run(self) -> None:
        while True:
            self._print_menu()
            action = self.input("Выберите действие: ").strip()

            if action == "1":
                self._add_lesson()
            elif action == "2":
                self._show_all_lessons()
            elif action == "3":
                self._find_lessons()
            elif action == "4":
                self._update_lesson()
            elif action == "5":
                self._delete_lesson()
            elif action == "6":
                self._sort_lessons()
            elif action == "0":
                self.output("Выход из программы.")
                break
            else:
                self.output("Неизвестная команда.")

    def _print_menu(self) -> None:
        self.output("\n=== База занятий по репетиторству ===")
        self.output("1. Добавить занятие")
        self.output("2. Показать все занятия")
        self.output("3. Найти занятия по фильтру")
        self.output("4. Обновить занятие")
        self.output("5. Удалить занятие")
        self.output("6. Отсортировать занятия")
        self.output("0. Выход")

    def _read_int(self, prompt: str) -> int:
        while True:
            raw = self.input(prompt).strip()

            try:
                return int(raw)
            except ValueError:
                self.output(
                    f"Ошибка: «{raw}» не является целым числом. Попробуйте ещё раз."
                )

    def _read_optional_int(self, prompt: str) -> int | None:
        raw = self.input(prompt).strip()

        if raw == "":
            return None

        try:
            return int(raw)
        except ValueError:
            self.output("Некорректное число, фильтр будет пропущен.")
            return None

    def _print_records(self, records: list[LessonRecord]) -> None:
        if not records:
            self.output("Записи не найдены.")
            return

        for record in records:
            self.output(
                f"{record.lesson_id}. Ученик: {record.student_name}, "
                f"предмет: {record.subject}, дата: {record.lesson_date}, "
                f"цена: {record.price} руб."
            )

    def _add_lesson(self) -> None:
        self.output("\nДобавление занятия")

        lesson_id = self._read_int("id: ")
        student_name = self.input("Имя ученика: ").strip()
        subject = self.input("Предмет: ").strip()
        lesson_date = self.input("Дата занятия, например 25.04.2026: ").strip()
        price = self._read_int("Стоимость: ")

        try:
            record = self.database.create_record(
                lesson_id,
                student_name,
                subject,
                lesson_date,
                price,
            )
        except ValueError as exc:
            self.output(f"Ошибка: {exc}")
            return

        self.output("Занятие добавлено:")
        self._print_records([record])

    def _show_all_lessons(self) -> None:
        self.output("\nВсе занятия")
        self._print_records(self.database.select_record())

    def _find_lessons(self) -> None:
        self.output("\nПоиск занятия. Enter означает пропустить поле.")

        lesson_id = self._read_optional_int("id: ")
        student_name = self.input("Имя ученика: ").strip() or None
        subject = self.input("Предмет: ").strip() or None
        lesson_date = self.input("Дата занятия: ").strip() or None
        price = self._read_optional_int("Стоимость: ")

        records = self.database.select_record(
            lesson_id=lesson_id,
            student_name=student_name,
            subject=subject,
            lesson_date=lesson_date,
            price=price,
        )
        self._print_records(records)

    def _update_lesson(self) -> None:
        self.output("\nОбновление занятия")

        lesson_id = self._read_int("id занятия: ")
        self.output("Оставьте поле пустым, если его не нужно менять.")

        student_name = self.input("Новое имя ученика: ").strip() or None
        subject = self.input("Новый предмет: ").strip() or None
        lesson_date = self.input("Новая дата занятия: ").strip() or None
        price = self._read_optional_int("Новая стоимость: ")

        try:
            record = self.database.update_record(
                lesson_id,
                student_name,
                subject,
                lesson_date,
                price,
            )
        except ValueError as exc:
            self.output(f"Ошибка: {exc}")
            return

        self.output("Занятие обновлено:")
        self._print_records([record])

    def _delete_lesson(self) -> None:
        self.output("\nУдаление занятия")

        lesson_id = self._read_int("id занятия: ")

        try:
            record = self.database.delete_record(lesson_id)
        except ValueError as exc:
            self.output(f"Ошибка: {exc}")
            return

        self.output("Удалена запись:")
        self._print_records([record])

    def _sort_lessons(self) -> None:
        self.output("\nСортировка занятий")
        self.output("Поля: id, student_name, subject, lesson_date, price")

        field_name = self.input("Поле сортировки: ").strip()
        order = self.input("Порядок (asc/desc): ").strip().lower()
        descending = order in {"desc", "убыв", "убывание"}

        try:
            records = self.database.sort_records(field_name, descending)
        except ValueError as exc:
            self.output(f"Ошибка: {exc}")
            return

        self._print_records(records)


def run() -> None:
    """Run the console interface with the default database."""
    LessonTUI().run()
