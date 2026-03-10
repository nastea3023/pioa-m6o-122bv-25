import json
import os

class Memories:
    """Класс для сохранения и загрузки нескольких таблиц"""
    
    def __init__(self, filename='database.json'):
        self.filename = filename
        self.data_dir = 'data'
        self.filepath = os.path.join(self.data_dir, filename)
        
        if not os.path.exists(self.data_dir):
            os.makedirs(self.data_dir)
    
    def save(self, database):
        """Сохранить все таблицы в файл"""
        tables_data = {}
        
        for table_name, table in database.tables.items():
            # Сохраняем данные каждой таблицы
            tables_data[table_name] = {
                'name': table.name,
                'columns': table.columns,
                'column_types': table.column_types,
                'rows': table.rows,
                'row_ids': table.row_ids,
                'deleted_rows': table.deleted_rows,
                'row_history': table.row_history,
                'next_row_id': table.next_row_id
            }
        
        data = {
            'tables': tables_data,
            'current_table': database.current_table,
            'version': '3.0'
        }
        
        try:
            with open(self.filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2, default=str)
            return True
        except Exception as e:
            print(f"Ошибка сохранения: {e}")
            return False
    
    def load(self, database):
        """Загрузить все таблицы из файла"""
        if not os.path.exists(self.filepath):
            return False
        
        try:
            with open(self.filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Очищаем текущие таблицы
            database.tables.clear()
            
            # Восстанавливаем таблицы
            for table_name, table_data in data.get('tables', {}).items():
                from backend.database import Table
                table = Table(table_name)
                
                table.columns = table_data.get('columns', [])
                table.column_types = table_data.get('column_types', {})
                table.rows = table_data.get('rows', [])
                table.row_ids = table_data.get('row_ids', [])
                table.deleted_rows = table_data.get('deleted_rows', [])
                table.row_history = table_data.get('row_history', [])
                table.next_row_id = table_data.get('next_row_id', 1)
                
                # Восстанавливаем поисковый индекс
                table._build_search_index()
                
                database.tables[table_name] = table
            
            # Восстанавливаем текущую таблицу
            database.current_table = data.get('current_table')
            
            # Если нет текущей таблицы, но есть таблицы - выбираем первую
            if not database.current_table and database.tables:
                database.current_table = list(database.tables.keys())[0]
            
            return True
        except Exception as e:
            print(f"Ошибка загрузки: {e}")
            return False
    
    def auto_save(self, database):
        """Автосохранение"""
        self.save(database)