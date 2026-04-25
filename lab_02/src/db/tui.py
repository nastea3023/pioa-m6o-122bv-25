from .backend.memory import (
    LessonRecord,
    create_record,
    delete_record,
    select_record,
    update_record,
)


def _print_menu() -> None:
    print("\n=== База занятий по репетиторству ===")
    print("1. Добавить занятие")
    print("2. Показать все занятия")
    print("3. Найти занятия по фильтру")
    print("4. Обновить занятие")
    print("5. Удалить занятие")
    print("0. Выход")


def _read_int(prompt: str) -> int:
    while True:
        raw = input(prompt).strip()

        try:
            return int(raw)
        except ValueError:
            print("Ошибка: введите целое число.")


def _read_optional_int(prompt: str) -> int | None:
    raw = input(prompt).strip()

    if raw == "":
        return None

    try:
        return int(raw)
    except ValueError:
        print("Некорректное число, фильтр будет пропущен.")
        return None


def _print_records(records: list[LessonRecord]) -> None:
    if not records:
        print("Записи не найдены.")
        return

    for lesson_id, student_name, subject, lesson_date, price in records:
        print(
            f"{lesson_id}. Ученик: {student_name}, предмет: {subject}, "
            f"дата: {lesson_date}, цена: {price} руб."
        )


def _add_lesson() -> None:
    print("\nДобавление занятия")

    lesson_id = _read_int("id: ")
    student_name = input("Имя ученика: ").strip()
    subject = input("Предмет: ").strip()
    lesson_date = input("Дата занятия, например 25.04.2026: ").strip()
    price = _read_int("Стоимость: ")

    try:
        record = create_record(lesson_id, student_name, subject, lesson_date, price)
    except ValueError as exc:
        print(f"Ошибка: {exc}")
        return

    print("Занятие добавлено:")
    _print_records([record])


def _show_all_lessons() -> None:
    print("\nВсе занятия")
    _print_records(select_record())


def _find_lessons() -> None:
    print("\nПоиск занятия. Enter означает пропустить поле.")

    lesson_id = _read_optional_int("id: ")
    student_name = input("Имя ученика: ").strip() or None
    subject = input("Предмет: ").strip() or None
    lesson_date = input("Дата занятия: ").strip() or None
    price = _read_optional_int("Стоимость: ")

    records = select_record(
        lesson_id=lesson_id,
        student_name=student_name,
        subject=subject,
        lesson_date=lesson_date,
        price=price,
    )
    _print_records(records)


def _update_lesson() -> None:
    print("\nОбновление занятия")

    lesson_id = _read_int("id занятия: ")
    print("Оставьте поле пустым, если его не нужно менять.")

    student_name = input("Новое имя ученика: ").strip() or None
    subject = input("Новый предмет: ").strip() or None
    lesson_date = input("Новая дата занятия: ").strip() or None
    price = _read_optional_int("Новая стоимость: ")

    try:
        record = update_record(lesson_id, student_name, subject, lesson_date, price)
    except ValueError as exc:
        print(f"Ошибка: {exc}")
        return

    print("Занятие обновлено:")
    _print_records([record])


def _delete_lesson() -> None:
    print("\nУдаление занятия")

    lesson_id = _read_int("id занятия: ")

    try:
        record = delete_record(lesson_id)
    except ValueError as exc:
        print(f"Ошибка: {exc}")
        return

    print("Удалена запись:")
    _print_records([record])


def run() -> None:
    while True:
        _print_menu()
        action = input("Выберите действие: ").strip()

        if action == "1":
            _add_lesson()
        elif action == "2":
            _show_all_lessons()
        elif action == "3":
            _find_lessons()
        elif action == "4":
            _update_lesson()
        elif action == "5":
            _delete_lesson()
        elif action == "0":
            print("Выход из программы.")
            break
        else:
            print("Неизвестная команда.")
