"""
Файловая СУБД для таблицы студентов с сохранением структуры и записей в JSON.
"""

import json
import os
from typing import Any

from .errors import DuplicateIDError, InvalidAgeError, FileStorageError

type StudentRecord = tuple[int, str, str, int, str]


class StudentTableFileStorage:
    """
    Файловая СУБД для таблицы студентов.

    Данные сохраняются в JSON-файл следующей структуры:
    {
        "structure": {
            "student_id": "int",
            "first_name": "str",
            "second_name": "str",
            "age": "int",
            "sex": "str"
        },
        "records": [
            [1, "John", "Doe", 20, "M"]
        ]
    }
    """

    DEFAULT_STRUCTURE: dict[str, str] = {
        "student_id": "int",
        "first_name": "str",
        "second_name": "str",
        "age": "int",
        "sex": "str",
    }

    def __init__(self, file_path: str = "student_table.json") -> None:
        self._file_path: str = file_path
        self._student: list[StudentRecord] = []
        self._structure: dict[str, str] = dict(self.DEFAULT_STRUCTURE)
        self._load()

    def _load(self) -> None:
        """Загружает данные из JSON-файла."""
        if not os.path.exists(self._file_path):
            self._student = []
            self._structure = dict(self.DEFAULT_STRUCTURE)
            return

        try:
            with open(self._file_path, "r", encoding="utf-8") as f:
                data: dict[str, Any] = json.load(f)

            self._structure = data.get("structure", dict(self.DEFAULT_STRUCTURE))
            records: list[list[Any]] = data.get("records", [])
            self._student = [tuple(record) for record in records]

        except (json.JSONDecodeError, KeyError, TypeError):
            self._student = []
            self._structure = dict(self.DEFAULT_STRUCTURE)

    def _save(self) -> None:
        """Сохраняет текущее состояние таблицы в JSON-файл."""
        data: dict[str, Any] = {
            "structure": self._structure,
            "records": [list(record) for record in self._student],
        }

        try:
            directory = os.path.dirname(self._file_path)
            if directory and not os.path.exists(directory):
                os.makedirs(directory, exist_ok=True)

            with open(self._file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)

        except OSError as exc:
            raise FileStorageError(
                f"Не удалось сохранить данные в файл '{self._file_path}': {exc}"
            ) from exc

    def create_record(
        self,
        student_id: int,
        first_name: str,
        second_name: str,
        age: int,
        sex: str,
    ) -> StudentRecord:
        """Создаёт новую запись и сохраняет её в файл."""
        if age < 0:
            raise InvalidAgeError("Поле age не может быть отрицательным.")

        if any(record[0] == student_id for record in self._student):
            raise DuplicateIDError(f"Запись с id={student_id} уже существует.")

        new_record: StudentRecord = (
            student_id,
            first_name.strip(),
            second_name.strip(),
            age,
            sex.strip(),
        )
        self._student.append(new_record)
        self._save()
        return new_record

    def select_record(
        self,
        student_id: int | None = None,
        first_name: str | None = None,
        second_name: str | None = None,
        age: int | None = None,
        sex: str | None = None,
    ) -> list[StudentRecord]:
        """Возвращает записи, удовлетворяющие фильтрам."""
        if all(
            value is None
            for value in (student_id, first_name, second_name, age, sex)
        ):
            return self._student.copy()

        result: list[StudentRecord] = []

        for record in self._student:
            if student_id is not None and record[0] != student_id:
                continue
            if first_name is not None and record[1] != first_name:
                continue
            if second_name is not None and record[2] != second_name:
                continue
            if age is not None and record[3] != age:
                continue
            if sex is not None and record[4] != sex:
                continue
            result.append(record)

        return result

    def get_structure(self) -> dict[str, str]:
        """Возвращает копию структуры таблицы."""
        return self._structure.copy()

    def clear(self) -> None:
        """Очищает таблицу и сохраняет изменения в файл."""
        self._student = []
        self._save()

    def __len__(self) -> int:
        return len(self._student)

    def __repr__(self) -> str:
        return (
            f"StudentTableFileStorage(file_path={self._file_path!r}, "
            f"records={len(self._student)})"
        )