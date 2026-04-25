"""Простая база занятий с репетитором, которая хранит данные в памяти."""

LessonRecord = tuple[int, str, str, str, int]


Lessons: list[LessonRecord] = []


def _check_text(value: str, field_name: str) -> str:
    value = value.strip()

    if value == "":
        raise ValueError(f"Поле '{field_name}' не должно быть пустым.")

    return value


def _find_index(lesson_id: int) -> int:
    for index, record in enumerate(Lessons):
        if record[0] == lesson_id:
            return index

    raise ValueError(f"Занятие с id={lesson_id} не найдено.")


def create_record(
    lesson_id: int,
    student_name: str,
    subject: str,
    lesson_date: str,
    price: int,
) -> LessonRecord:
    """Добавляет новое занятие в таблицу Lessons."""
    if lesson_id <= 0:
        raise ValueError("id должен быть положительным числом.")

    if price < 0:
        raise ValueError("Стоимость занятия не может быть отрицательной.")

    for record in Lessons:
        if record[0] == lesson_id:
            raise ValueError(f"Занятие с id={lesson_id} уже существует.")

    new_record: LessonRecord = (
        lesson_id,
        _check_text(student_name, "имя ученика"),
        _check_text(subject, "предмет"),
        _check_text(lesson_date, "дата занятия"),
        price,
    )

    Lessons.append(new_record)
    return new_record


def select_record(
    lesson_id: int | None = None,
    student_name: str | None = None,
    subject: str | None = None,
    lesson_date: str | None = None,
    price: int | None = None,
) -> list[LessonRecord]:
    """Возвращает занятия, подходящие под заданные фильтры."""
    if student_name is not None:
        student_name = student_name.strip().lower()

    if subject is not None:
        subject = subject.strip().lower()

    if lesson_date is not None:
        lesson_date = lesson_date.strip()

    result: list[LessonRecord] = []

    for record in Lessons:
        if lesson_id is not None and record[0] != lesson_id:
            continue

        if student_name is not None and record[1].lower() != student_name:
            continue

        if subject is not None and record[2].lower() != subject:
            continue

        if lesson_date is not None and record[3] != lesson_date:
            continue

        if price is not None and record[4] != price:
            continue

        result.append(record)

    return result


def update_record(
    lesson_id: int,
    student_name: str | None = None,
    subject: str | None = None,
    lesson_date: str | None = None,
    price: int | None = None,
) -> LessonRecord:
    """Обновляет занятие по id."""
    index = _find_index(lesson_id)
    old_record = Lessons[index]

    if price is not None and price < 0:
        raise ValueError("Стоимость занятия не может быть отрицательной.")

    new_record: LessonRecord = (
        old_record[0],
        old_record[1]
        if student_name is None
        else _check_text(student_name, "имя ученика"),
        old_record[2] if subject is None else _check_text(subject, "предмет"),
        old_record[3]
        if lesson_date is None
        else _check_text(lesson_date, "дата занятия"),
        old_record[4] if price is None else price,
    )

    Lessons[index] = new_record
    return new_record


def delete_record(lesson_id: int) -> LessonRecord:
    """Удаляет занятие по id и возвращает удаленную запись."""
    index = _find_index(lesson_id)
    return Lessons.pop(index)
