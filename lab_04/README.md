# Лабораторная работа №4: Файловая СУБД с сохранением в JSON

## Описание

Реализована файловая СУБД для таблицы студентов с сохранением
структуры таблицы и записей в формате JSON.

## Структура JSON-файла

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

## Использование

from lab_04.src.db.backend.file_storage import StudentTableFileStorage

storage = StudentTableFileStorage("student_table.json")
storage.create_record(1, "John", "Doe", 20, "M")
records = storage.select_record(sex="M")

## Запуск тестов

python -m unittest discover lab_04/tests -v