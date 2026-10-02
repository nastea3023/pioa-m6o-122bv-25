class StudentTableError(Exception):
    """Базовый класс для ошибок, связанных с таблицей Student."""


class InvalidAgeError(StudentTableError):
    """Ошибка, возникающая при попытке создать запись с некорректным возрастом."""


class DuplicateIDError(StudentTableError):
    """Ошибка, возникающая при попытке создать запись с уже существующим идентификатором."""


class FileStorageError(StudentTableError):
    """Ошибка, возникающая при работе с файловым хранилищем."""
