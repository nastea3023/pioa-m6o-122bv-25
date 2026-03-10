import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from backend.database import Database
from backend.sorters import Sorter
from backend.memories import Memories

class ConsoleUI:
    def __init__(self):
        self.db = Database()
        self.sorter = Sorter()
        self.memories = Memories()
        self.selected_row = -1
        self.selected_col = -1
        
        # Пытаемся загрузить сохраненные таблицы
        if self.memories.load(self.db):
            print(f"✅ Загружено {len(self.db.tables)} таблиц из data/database.json")
        else:
            print("📁 Создана новая пустая база данных")
            self.db.create_table("Таблица 1")
    
    def auto_save(self):
        """Автосохранение после изменений"""
        if hasattr(self.db, 'changed') and self.db.changed:
            self.memories.auto_save(self.db)
            self.db.changed = False
    
    def clear_screen(self):
        """Очистка экрана"""
        os.system('cls' if os.name == 'nt' else 'clear')
    
    def print_table_with_selection(self, data=None):
        """Вывод таблицы с выделением"""
        if data is None:
            data = self.db.get_all_data()
        
        # Показываем статус сохранения
        save_status = "💾" if os.path.exists(self.memories.filepath) else "🆕"
        
        current_table = self.db.current_table or "Нет таблицы"
        print(f"{save_status} Текущая таблица: \033[36m{current_table}\033[0m")
        print(f"📊 Всего таблиц: {len(self.db.tables)} | Файл: {self.memories.filepath}")
        print()
        
        if not data['columns']:
            print("Таблица пуста. Добавьте столбцы или создайте тестовую таблицу (T5).")
            return
        
        display_cols = ['№'] + data['columns']
        
        # Определяем ширину колонок
        col_widths = {}
        max_row_num = len(str(len(data['rows'])))
        col_widths['№'] = max(max_row_num, 3) + 2
        
        for i, col in enumerate(data['columns']):
            max_width = len(str(col))
            for row in data['rows']:
                val = row.get(col, '')
                if isinstance(val, list):
                    val = f"[{len(val)}]"
                else:
                    val = str(val)
                max_width = max(max_width, len(val))
            col_widths[col] = max_width + 2
        
        # Верхняя граница
        print('┌' + '┬'.join(['─' * col_widths[col] for col in display_cols]) + '┐')
        
        # Заголовки
        header = '│'
        header += '   №   │'
        for i, col in enumerate(data['columns']):
            col_num = i + 1
            header += f"{col} [{col_num}]".center(col_widths[col]) + '│'
        print(header)
        
        # Разделитель
        print('├' + '┼'.join(['─' * col_widths[col] for col in display_cols]) + '┤')
        
        # Данные
        for row_idx, row in enumerate(data['rows']):
            # Подсветка выбранной строки
            if row_idx == self.selected_row:
                line = '│\033[42m'
            else:
                line = '│'
            
            # Номер строки
            row_num = f" {row_idx + 1} ".center(col_widths['№'])
            line += row_num + '│'
            
            # Значения
            for col_idx, col in enumerate(data['columns']):
                val = row.get(col, '')
                
                # Красивое отображение разных типов
                if isinstance(val, list):
                    display_val = f"list[{len(val)}]"
                elif isinstance(val, bool):
                    display_val = "✅" if val else "❌"
                elif val == "" or val is None:
                    display_val = "—"
                else:
                    display_val = str(val)
                
                display_val = display_val.center(col_widths[col])
                
                # Подсветка выбранной ячейки
                if row_idx == self.selected_row and col_idx == self.selected_col:
                    line += f'\033[43m{display_val}\033[0m│'
                else:
                    line += display_val + '│'
            
            if row_idx == self.selected_row:
                line += '\033[0m'
            print(line)
        
        # Нижняя граница
        print('└' + '┴'.join(['─' * col_widths[col] for col in display_cols]) + '┘')
        
        # Информация о выбранном
        if self.selected_row != -1:
            print(f"\n\033[33m▶ Строка: {self.selected_row + 1}\033[0m", end='')
        if self.selected_col != -1:
            col_name = data['columns'][self.selected_col]
            print(f"\033[33m | Столбец: {self.selected_col + 1} ({col_name})\033[0m", end='')
        if self.selected_row != -1 and self.selected_col != -1:
            current_value = data['rows'][self.selected_row].get(col_name, '')
            if isinstance(current_value, list):
                current_value = f"list({current_value})"
            print(f"\033[33m | Значение: {current_value}\033[0m")
        else:
            print()
        
        print(f"\nВсего строк: {len(data['rows'])} | Всего столбцов: {len(data['columns'])}")
    
    def run(self):
        """Главный цикл программы"""
        while True:
            self.clear_screen()
            print("╔════════════════════════════════════════════╗")
            print("║    КОНСОЛЬНАЯ БД (С сохранением)         ║")
            print("╚════════════════════════════════════════════╝\n")
            
            self.print_table_with_selection()
            
            selection_status = f"ВЫБРАНО: Строка - {self.selected_row + 1 if self.selected_row != -1 else '?'} | Столбец - {self.selected_col + 1 if self.selected_col != -1 else '?'}"
            
            print("\n╔══════════════════════════════════════════════════════════════╗")
            print("║                         МЕНЮ КОМАНД                          ║")
            print("╠══════════════════════════════════════════════════════════════╣")
            print("║  🔧 РАБОТА С ТАБЛИЦАМИ:                                      ║")
            print("║  T1 - Создать таблицу        | T2 - Переключить таблицу      ║")
            print("║  T3 - Переименовать таблицу  | T4 - Удалить таблицу          ║")
            print("║  T5 - Тестовая таблица       | S  - Сохранить сейчас         ║")
            print("╠══════════════════════════════════════════════════════════════╣")
            print("║  📝 РАБОТА С ДАННЫМИ:                                        ║")
            print("║   1 - Выбрать строку         |  2 - Выбрать столбец           ║")
            print("║   3 - Редактировать ячейку   |  4 - Добавить столбец          ║")
            print("║   5 - Добавить строку        |  6 - Удалить строку            ║")
            print("║   7 - Удалить столбец        |  8 - Сортировать               ║")
            print("║   9 - Сбросить выбор         | 10 - Поиск по значению         ║")
            print("║  11 - Показать статистику    | 12 - Восстановить удаленное    ║")
            print("║  13 - История изменений      |  0 - Выход                     ║")
            print("╠══════════════════════════════════════════════════════════════╣")
            print(f"║  {selection_status:<60} ║")
            print("╚══════════════════════════════════════════════════════════════╝\n")
            
            choice = input("Выберите команду: ").strip().upper()
            
            # Сохраняем состояние ДО операции
            old_changed = self.db.changed
            
            # Команды для таблиц
            if choice == 'T1':
                self.create_table_dialog()
            elif choice == 'T2':
                self.switch_table_dialog()
            elif choice == 'T3':
                self.rename_table_dialog()
            elif choice == 'T4':
                self.delete_table_dialog()
            elif choice == 'T5':
                self.create_test_table_dialog()
            elif choice == 'S':
                if self.memories.save(self.db):
                    print("✅ База данных сохранена в data/database.json")
                else:
                    print("❌ Ошибка сохранения!")
            
            # Команды для работы с данными
            elif choice == '1':
                self.select_row_dialog()
            elif choice == '2':
                self.select_column_dialog()
            elif choice == '3':
                self.edit_selected_cell()
            elif choice == '4':
                self.add_column_dialog()
            elif choice == '5':
                self.add_row_dialog()
            elif choice == '6':
                self.delete_selected_row()
            elif choice == '7':
                self.delete_selected_column()
            elif choice == '8':
                self.sort_dialog()
            elif choice == '9':
                self.selected_row = -1
                self.selected_col = -1
                print("✅ Выбор сброшен")
            elif choice == '10':
                self.search_dialog()
            elif choice == '11':
                self.show_stats()
            elif choice == '12':
                self.restore_deleted_dialog()
            elif choice == '13':
                self.show_history()
            elif choice == '0':
                # Сохраняем при выходе
                if self.db.changed:
                    self.memories.save(self.db)
                    print("💾 Данные сохранены")
                print("👋 До свидания!")
                break
            else:
                print("❌ Неверная команда!")
            
            # Автосохранение если были изменения
            if self.db.changed != old_changed and self.db.changed:
                self.memories.auto_save(self.db)
                print("💾 Автосохранение...")
            
            input("\nНажмите Enter для продолжения...")
    
    # ==================== ДИАЛОГИ ДЛЯ ТАБЛИЦ ====================
    
    def create_table_dialog(self):
        """Создание новой таблицы"""
        name = input("Введите имя новой таблицы: ").strip()
        if not name:
            print("❌ Имя не может быть пустым")
            return
        
        if self.db.create_table(name):
            print(f"✅ Таблица '{name}' создана и активирована")
            self.selected_row = -1
            self.selected_col = -1
        else:
            print(f"❌ Таблица с именем '{name}' уже существует")
    
    def switch_table_dialog(self):
        """Переключение между таблицами"""
        tables = self.db.get_table_names()
        if not tables:
            print("❌ Нет доступных таблиц")
            return
        
        print("\n📋 Доступные таблицы:")
        for i, name in enumerate(tables, 1):
            current = " ◀ ТЕКУЩАЯ" if name == self.db.current_table else ""
            print(f"  {i}. {name}{current}")
        
        try:
            choice = int(input("\nВыберите номер таблицы: "))
            if 1 <= choice <= len(tables):
                name = tables[choice-1]
                self.db.switch_table(name)
                self.selected_row = -1
                self.selected_col = -1
                print(f"✅ Переключено на таблицу '{name}'")
            else:
                print("❌ Неверный номер")
        except ValueError:
            print("❌ Введите число")
    
    def rename_table_dialog(self):
        """Переименование таблицы"""
        old_name = input("Введите текущее имя таблицы: ").strip()
        new_name = input("Введите новое имя таблицы: ").strip()
        
        if not old_name or not new_name:
            print("❌ Имена не могут быть пустыми")
            return
        
        if self.db.rename_table(old_name, new_name):
            print(f"✅ Таблица переименована в '{new_name}'")
        else:
            print("❌ Не удалось переименовать таблицу")
    
    def delete_table_dialog(self):
        """Удаление таблицы"""
        name = input("Введите имя таблицы для удаления: ").strip()
        
        if not name:
            print("❌ Имя не может быть пустым")
            return
        
        if name == self.db.current_table:
            print("❌ Нельзя удалить текущую таблицу! Сначала переключитесь на другую.")
            return
        
        confirm = input(f"⚠️ Удалить таблицу '{name}'? Все данные пропадут! (да/нет): ").lower()
        if confirm == 'да':
            if self.db.delete_table(name):
                print(f"✅ Таблица '{name}' удалена")
            else:
                print("❌ Таблица не найдена")
    
    def create_test_table_dialog(self):
        """Создание тестовой таблицы"""
        name = input("Введите имя для тестовой таблицы (Enter - 'Тестовая'): ").strip()
        if not name:
            name = "Тестовая"
        
        if self.db.create_test_table(name):
            print(f"✅ Создана тестовая таблица '{name}' с демо-данными")
            self.selected_row = -1
            self.selected_col = -1
        else:
            print(f"❌ Таблица '{name}' уже существует")
    
    # ==================== ДИАЛОГИ ДЛЯ РАБОТЫ С ДАННЫМИ ====================
    
    def select_row_dialog(self):
        """Выбор строки по номеру"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        if not table.rows:
            print("❌ В таблице нет строк!")
            return
        
        try:
            row_num = int(input(f"Введите номер строки (1-{len(table.rows)}): "))
            if 1 <= row_num <= len(table.rows):
                self.selected_row = row_num - 1
                print(f"✅ Выбрана строка {row_num}")
            else:
                print(f"❌ Неверный номер! Введите от 1 до {len(table.rows)}")
        except ValueError:
            print("❌ Ошибка: введите число!")
    
    def select_column_dialog(self):
        """Выбор столбца по номеру"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        if not table.columns:
            print("❌ В таблице нет столбцов!")
            return
        
        try:
            col_num = int(input(f"Введите номер столбца (1-{len(table.columns)}): "))
            if 1 <= col_num <= len(table.columns):
                self.selected_col = col_num - 1
                col_name = table.columns[self.selected_col]
                print(f"✅ Выбран столбец {col_num} ({col_name})")
            else:
                print(f"❌ Неверный номер! Введите от 1 до {len(table.columns)}")
        except ValueError:
            print("❌ Ошибка: введите число!")
    
    def edit_selected_cell(self):
        """Редактирование выбранной ячейки"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        if self.selected_row == -1:
            print("❌ Сначала выберите строку (команда 1)!")
            return
        if self.selected_col == -1:
            print("❌ Сначала выберите столбец (команда 2)!")
            return
        
        col_name = table.columns[self.selected_col]
        current_value = table.rows[self.selected_row].get(col_name, '')
        
        print(f"\n📝 Редактирование ячейки [строка {self.selected_row + 1}, столбец '{col_name}']")
        print(f"Текущее значение: {current_value}")
        print("(Enter - оставить, 'del' - очистить)")
        
        new_value = input("Новое значение: ").strip()
        
        if new_value.lower() == 'del':
            table.update_cell(self.selected_row, col_name, '')
            print("✅ Значение очищено!")
        elif new_value:
            table.update_cell(self.selected_row, col_name, new_value)
            print("✅ Значение обновлено!")
        else:
            print("⏭️ Изменений не внесено")
    
    def add_column_dialog(self):
        """Добавление нового столбца"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        col_name = input("Введите название столбца: ").strip()
        if not col_name:
            print("❌ Название не может быть пустым")
            return
        
        if table.add_column(col_name):
            print(f"✅ Столбец '{col_name}' добавлен")
        else:
            print(f"❌ Столбец '{col_name}' уже существует")
    
    def add_row_dialog(self):
        """Добавление новой строки"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        if not table.columns:
            print("❌ Сначала добавьте столбцы!")
            return
        
        values = {}
        print("📝 Введите значения (Enter - пропустить):")
        for i, col in enumerate(table.columns):
            val = input(f"  {col} [{i+1}]: ").strip()
            if val:
                values[col] = val
        
        row_idx = table.add_row(**values)
        print(f"✅ Строка {row_idx + 1} добавлена")
    
    def delete_selected_row(self):
        """Удаление выбранной строки"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        if self.selected_row == -1:
            print("❌ Сначала выберите строку (команда 1)!")
            return
        
        confirm = input(f"⚠️ Удалить строку {self.selected_row + 1}? (да/нет): ").lower()
        if confirm == 'да':
            table.delete_row(self.selected_row)
            print("✅ Строка удалена")
            self.selected_row = -1
            self.selected_col = -1
    
    def delete_selected_column(self):
        """Удаление выбранного столбца"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        if self.selected_col == -1:
            print("❌ Сначала выберите столбец (команда 2)!")
            return
        
        col_name = table.columns[self.selected_col]
        confirm = input(f"⚠️ Удалить столбец '{col_name}'? (да/нет): ").lower()
        if confirm == 'да':
            table.delete_column(col_name)
            print(f"✅ Столбец '{col_name}' удален")
            self.selected_col = -1
    
    def sort_dialog(self):
        """Сортировка по выбранному столбцу"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        if self.selected_col == -1:
            print("❌ Сначала выберите столбец для сортировки (команда 2)!")
            return
        
        col_name = table.columns[self.selected_col]
        reverse = input("По убыванию? (да/нет): ").lower() == 'да'
        
        sorted_data = self.sorter.sort_by_column(
            table.get_all_data(), 
            col_name, 
            reverse
        )
        table.rows = sorted_data['rows']
        table.changed = True
        print(f"✅ Таблица отсортирована по столбцу '{col_name}'")
    
    def search_dialog(self):
        """Поиск по значению"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        value = input("Введите значение для поиска: ").strip()
        if not value:
            return
        
        results = table.search_by_value(value)
        
        if results:
            print(f"\n🔍 Найдено в {len(results)} местах:")
            for row_idx, col in results:
                row_num = row_idx + 1
                col_num = table.columns.index(col) + 1
                print(f"  • Строка {row_num}, Столбец {col_num} ({col})")
        else:
            print("❌ Ничего не найдено")
    
    def show_stats(self):
        """Показать статистику"""
        stats = self.db.get_stats()
        
        print("\n" + "="*50)
        print("📊 СТАТИСТИКА БАЗЫ ДАННЫХ")
        print("="*50)
        
        print(f"\n📌 Всего таблиц: {stats['total_tables']}")
        print(f"📍 Текущая таблица: {stats['current']}")
        
        print("\n📋 Таблицы:")
        for name, table_stats in stats['tables'].items():
            current = "◀" if name == stats['current'] else " "
            print(f"  {current} {name}:")
            print(f"     • Столбцов: {table_stats['columns']}")
            print(f"     • Строк: {table_stats['rows']}")
            print(f"     • В корзине: {table_stats['deleted']}")
            print(f"     • Записей истории: {table_stats['history']}")
    
    def restore_deleted_dialog(self):
        """Восстановление последней удаленной строки"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        if table.restore_last_deleted():
            print("✅ Последняя удаленная строка восстановлена!")
        else:
            print("❌ Нет удаленных строк")
    
    def show_history(self):
        """Показать историю изменений"""
        table = self.db.get_current_table()
        if not table:
            print("❌ Нет активной таблицы!")
            return
        
        history = table.row_history[-20:]  # последние 20 записей
        
        print("\n" + "="*50)
        print("📜 ИСТОРИЯ ИЗМЕНЕНИЙ")
        print("="*50)
        
        if not history:
            print("История пуста")
            return
        
        for i, (action, row_id, data) in enumerate(history, 1):
            if action == "add":
                print(f"{i}. ➕ Добавлена строка ID={row_id}")
            elif action == "update":
                col = data.get('column', '?')
                old = data.get('old', '?')
                new = data.get('new', '?')
                print(f"{i}. ✏️ Обновлена строка ID={row_id}: {col} = {new} (было: {old})")
            elif action == "delete":
                print(f"{i}. 🗑️ Удалена строка ID={row_id}")