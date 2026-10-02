# Лабораторная работа №4: Файловая СУБД с сохранением в JSON

## Описание

В рамках лабораторной работы реализована файловая СУБД
`StudentTableFileStorage` для таблицы студентов с сохранением
структуры таблицы и записей в формате JSON.

Работа развивает in-memory реализацию из лабораторной работы №3,
добавляя постоянное хранилище на диске.

## Структура проекта

```
lab_04/
├── README.md
├── src/
│   ├── __init__.py
│   └── db/
│       ├── __init__.py
│       └── backend/
│           ├── __init__.py
│           ├── errors.py          # Пользовательские исключения
│           └── file_storage.py    # Файловая СУБД
└── tests/
    ├── __init__.py
    └── test_file_storage.py       # Тесты
```

## Функциональность

Класс `StudentTableFileStorage` предоставляет:

- **`__init__(file_path)`** — создание/загрузка таблицы из JSON-файла.
- **`create_record(student_id, first_name, second_name, age, sex)`** —
  создание новой записи с валидацией. Автоматически сохраняет в файл.
- **`select_record(...)`** — выборка записей по фильтрам
  (student_id, first_name, second_name, age, sex).
- **`get_structure()`** — получение структуры таблицы.
- **`clear()`** — очистка таблицы с сохранением изменений.
- **`__len__()`** — количество записей в таблице.

### Пользовательские исключения

- `InvalidAgeError` — возраст не может быть отрицательным.
- `DuplicateIDError` — запись с таким `id` уже существует.
- `FileStorageError` — ошибка при работе с файлом.

## Структура JSON-файла

```json
{
  "structure": {
    "student_id": "int",
    "first_name": "str",
    "second_name": "str",
    "age": "int",
    "sex": "str"
  },
  "records": [
    [1, "John", "Doe", 20, "M"],
    [2, "Jane", "Smith", 22, "F"]
  ]
}
```

Поле `structure` хранит описание полей и их типов, а `records` — сами
записи в виде массивов.

## Установка

```bash
git clone https://github.com/nastea3023/pioa-m6o-122bv-25.git
cd pioa-m6o-122bv-25
git checkout lab_04
```

Требуется Python 3.12+ (из-за использования синтаксиса `type StudentRecord = ...`).

## Использование

```python
from lab_04.src.db.backend.file_storage import StudentTableFileStorage
from lab_04.src.db.backend.errors import DuplicateIDError, InvalidAgeError


storage = StudentTableFileStorage("student_table.json")


storage.create_record(1, "John", "Doe", 20, "M")
storage.create_record(2, "Jane", "Smith", 22, "F")


records = storage.select_record(sex="M")
print(records)  # [(1, 'John', 'Doe', 20, 'M')]


all_records = storage.select_record()


try:
    storage.create_record(1, "Duplicate", "ID", 25, "M")
except DuplicateIDError as e:
    print(f"Ошибка: {e}")

try:
    storage.create_record(3, "Bad", "Age", -5, "M")
except InvalidAgeError as e:
    print(f"Ошибка: {e}")
```

## Запуск тестов

Из **корня репозитория** (`pioa-m6o-122bv-25/`):

```bash
python -m unittest discover lab_04/tests -v
```

Ожидаемый результат — все 15 тестов проходят:

```
test_clear ... ok
test_create_record ... ok
test_create_record_duplicate_id ... ok
test_create_record_negative_age ... ok
test_create_record_strips_whitespace ... ok
test_get_structure ... ok
test_len ... ok
test_load_corrupted_file ... ok
test_load_existing_file ... ok
test_load_nonexistent_file ... ok
test_save_creates_file ... ok
test_save_records ... ok
test_save_structure ... ok
test_select_record_by_id ... ok
test_select_record_by_sex ... ok

----------------------------------------------------------------------
Ran 15 tests in 0.XXXs

OK
```

## Проверка покрытия (опционально)

```bash
pip install pytest pytest-cov
pytest --cov=lab_04/src --cov-report=term-missing lab_04/tests
```

## Автор

nastea3023