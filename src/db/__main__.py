"""Entry point for the tutoring lessons database."""

import argparse

from .tui import run


def main() -> None:
    parser = argparse.ArgumentParser(
        description="База занятий по репетиторству."
    )
    parser.add_argument(
        "--file",
        action="store_true",
        help="Использовать файловую базу данных (JSON) вместо in-memory.",
    )
    parser.add_argument(
        "--path",
        default="lessons.json",
        help="Путь к JSON-файлу (по умолчанию: lessons.json).",
    )
    args = parser.parse_args()

    run(use_file=args.file, file_path=args.path)


if __name__ == "__main__":
    main()
