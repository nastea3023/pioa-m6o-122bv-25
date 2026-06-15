"""In-memory database for tutoring lessons."""

from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class LessonRecord:
    """A single tutoring lesson."""

    lesson_id: int
    student_name: str
    subject: str
    lesson_date: str
    price: int


class LessonDatabase:
    """Stores lesson records and provides CRUD operations."""

    _SORT_FIELDS = {
        "id": "lesson_id",
        "lesson_id": "lesson_id",
        "student_name": "student_name",
        "subject": "subject",
        "lesson_date": "lesson_date",
        "price": "price",
    }

    def __init__(self, records: Iterable[LessonRecord] | None = None) -> None:
        self._records: list[LessonRecord] = []
        if records is not None:
            for record in records:
                self.add(record)

    def create_record(
        self,
        lesson_id: int,
        student_name: str,
        subject: str,
        lesson_date: str,
        price: int,
    ) -> LessonRecord:
        """Add a lesson to the database."""
        self._validate_id(lesson_id)
        self._validate_price(price)

        if any(record.lesson_id == lesson_id for record in self._records):
            raise ValueError(f"Занятие с id={lesson_id} уже существует.")

        record = LessonRecord(
            lesson_id=lesson_id,
            student_name=self._check_text(student_name, "имя ученика"),
            subject=self._check_text(subject, "предмет"),
            lesson_date=self._check_text(lesson_date, "дата занятия"),
            price=price,
        )
        self._records.append(record)
        return record

    def select_record(
        self,
        lesson_id: int | None = None,
        student_name: str | None = None,
        subject: str | None = None,
        lesson_date: str | None = None,
        price: int | None = None,
    ) -> list[LessonRecord]:
        """Return lessons matching the given filters."""
        normalized_student_name = self._normalize_optional_text(student_name)
        normalized_subject = self._normalize_optional_text(subject)
        normalized_lesson_date = self._strip_optional_text(lesson_date)

        result: list[LessonRecord] = []

        for record in self._records:
            if lesson_id is not None and record.lesson_id != lesson_id:
                continue

            if (
                normalized_student_name is not None
                and record.student_name.lower() != normalized_student_name
            ):
                continue

            if normalized_subject is not None and record.subject.lower() != normalized_subject:
                continue

            if normalized_lesson_date is not None and record.lesson_date != normalized_lesson_date:
                continue

            if price is not None and record.price != price:
                continue

            result.append(record)

        return result

    def update_record(
        self,
        lesson_id: int,
        student_name: str | None = None,
        subject: str | None = None,
        lesson_date: str | None = None,
        price: int | None = None,
    ) -> LessonRecord:
        """Update a lesson by id."""
        index = self._find_index(lesson_id)
        old_record = self._records[index]

        if price is not None:
            self._validate_price(price)

        record = LessonRecord(
            lesson_id=old_record.lesson_id,
            student_name=old_record.student_name
            if student_name is None
            else self._check_text(student_name, "имя ученика"),
            subject=old_record.subject
            if subject is None
            else self._check_text(subject, "предмет"),
            lesson_date=old_record.lesson_date
            if lesson_date is None
            else self._check_text(lesson_date, "дата занятия"),
            price=old_record.price if price is None else price,
        )

        self._records[index] = record
        return record

    def delete_record(self, lesson_id: int) -> LessonRecord:
        """Delete a lesson by id and return the deleted record."""
        index = self._find_index(lesson_id)
        return self._records.pop(index)

    def sort_records(self, field_name: str, descending: bool = False) -> list[LessonRecord]:
        """Return records sorted by the selected field."""
        attribute = self._SORT_FIELDS.get(field_name.strip().lower())

        if attribute is None:
            allowed_fields = ", ".join(sorted(self._SORT_FIELDS))
            raise ValueError(f"Неизвестное поле сортировки. Доступно: {allowed_fields}.")

        return sorted(
            self._records,
            key=lambda record: getattr(record, attribute),
            reverse=descending,
        )

    def _find_index(self, lesson_id: int) -> int:
        for index, record in enumerate(self._records):
            if record.lesson_id == lesson_id:
                return index

        raise ValueError(f"Занятие с id={lesson_id} не найдено.")

    @staticmethod
    def _check_text(value: str, field_name: str) -> str:
        value = value.strip()

        if value == "":
            raise ValueError(f"Поле '{field_name}' не должно быть пустым.")

        return value

    @staticmethod
    def _validate_id(lesson_id: int) -> None:
        if lesson_id <= 0:
            raise ValueError("id должен быть положительным числом.")

    @staticmethod
    def _validate_price(price: int) -> None:
        if price < 0:
            raise ValueError("Стоимость занятия не может быть отрицательной.")

    @staticmethod
    def _normalize_optional_text(value: str | None) -> str | None:
        if value is None:
            return None

        return value.strip().lower()

    @staticmethod
    def _strip_optional_text(value: str | None) -> str | None:
        if value is None:
            return None

        return value.strip()


default_database = LessonDatabase()
