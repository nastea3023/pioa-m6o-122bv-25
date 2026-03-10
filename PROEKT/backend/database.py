class Table:
    def __init__(self, name):
        self.name = name
        self.columns = []
        self.column_types = {}
        self.rows = []
        self.row_ids = []
        self.deleted_rows = []
        self.row_history = []
        self.search_index = {}
        self.next_row_id = 1
        self.changed = False
    
    def _build_search_index(self):
        """Построение поискового индекса"""
        self.search_index.clear()
        for row_idx, row in enumerate(self.rows):
            for col in self.columns:
                value = str(row.get(col, ''))
                if value:
                    if value not in self.search_index:
                        self.search_index[value] = []
                    self.search_index[value].append((row_idx, col))
    
    def add_column(self, column_name, col_type="string"):
        if column_name not in self.columns:
            self.columns.append(column_name)
            self.column_types[column_name] = col_type
            
            for row in self.rows:
                if col_type == "list":
                    row[column_name] = []
                elif col_type == "number":
                    row[column_name] = 0
                elif col_type == "boolean":
                    row[column_name] = False
                else:
                    row[column_name] = ""
            
            self.changed = True
            return True
        return False
    
    def add_row(self, **values):
        row = {}
        row_id = self.next_row_id
        self.next_row_id += 1
        
        for col in self.columns:
            col_type = self.column_types.get(col, "string")
            if col in values:
                value = values[col]
                if col_type == "number":
                    try:
                        row[col] = int(value) if value else 0
                    except:
                        row[col] = 0
                elif col_type == "boolean":
                    if isinstance(value, bool):
                        row[col] = value
                    else:
                        row[col] = str(value).lower() in ['true', 'да', '1', 'yes']
                elif col_type == "list":
                    if isinstance(value, list):
                        row[col] = value
                    else:
                        row[col] = [value]
                else:
                    row[col] = str(value)
            else:
                if col_type == "list":
                    row[col] = []
                elif col_type == "number":
                    row[col] = 0
                elif col_type == "boolean":
                    row[col] = False
                else:
                    row[col] = ""
        
        self.rows.append(row)
        self.row_ids.append(row_id)
        self.row_history.append(("add", row_id, row.copy()))
        self._build_search_index()
        self.changed = True
        return len(self.rows) - 1
    
    def update_cell(self, row_index, column_name, value):
        if 0 <= row_index < len(self.rows) and column_name in self.columns:
            old_value = self.rows[row_index].get(column_name)
            row_id = self.row_ids[row_index]
            
            col_type = self.column_types.get(column_name, "string")
            if col_type == "number":
                try:
                    value = int(value) if value else 0
                except:
                    value = 0
            elif col_type == "boolean":
                if isinstance(value, bool):
                    pass
                else:
                    value = str(value).lower() in ['true', 'да', '1', 'yes']
            elif col_type == "list":
                if isinstance(value, list):
                    pass
                else:
                    value = [value]
            
            self.rows[row_index][column_name] = value
            
            self.row_history.append(("update", row_id, {
                "column": column_name,
                "old": old_value,
                "new": value
            }))
            
            self._build_search_index()
            self.changed = True
            return True
        return False
    
    def delete_row(self, row_index):
        if 0 <= row_index < len(self.rows):
            row_id = self.row_ids.pop(row_index)
            deleted_row = self.rows.pop(row_index)
            
            self.deleted_rows.append({
                "id": row_id,
                "row": deleted_row,
                "index": row_index
            })
            
            self.row_history.append(("delete", row_id, deleted_row))
            self._build_search_index()
            self.changed = True
            return True
        return False
    
    def restore_last_deleted(self):
        if self.deleted_rows:
            deleted = self.deleted_rows.pop()
            self.rows.insert(deleted["index"], deleted["row"])
            self.row_ids.insert(deleted["index"], deleted["id"])
            self._build_search_index()
            self.changed = True
            return True
        return False
    
    def delete_column(self, column_name):
        if column_name in self.columns:
            self.columns.remove(column_name)
            del self.column_types[column_name]
            for row in self.rows:
                if column_name in row:
                    del row[column_name]
            self._build_search_index()
            self.changed = True
            return True
        return False
    
    def search_by_value(self, value):
        return self.search_index.get(str(value), [])
    
    def get_all_data(self):
        return {
            'name': self.name,
            'columns': self.columns,
            'rows': self.rows,
            'types': self.column_types
        }
    
    def get_stats(self):
        return {
            'name': self.name,
            'columns': len(self.columns),
            'rows': len(self.rows),
            'deleted': len(self.deleted_rows),
            'history': len(self.row_history)
        }
    
    def create_test_data(self):
        self.add_column("ID", "number")
        self.add_column("Имя", "string")
        self.add_column("Возраст", "number")
        self.add_column("Город", "string")
        self.add_column("Активен", "boolean")
        
        test_data = [
            {"ID": 1, "Имя": "Анна", "Возраст": 25, "Город": "Москва", "Активен": True},
            {"ID": 2, "Имя": "Иван", "Возраст": 30, "Город": "СПб", "Активен": False},
            {"ID": 3, "Имя": "Мария", "Возраст": 28, "Город": "Казань", "Активен": True},
        ]
        
        for data in test_data:
            self.add_row(**data)
        
        self.changed = True
        return True


class Database:
    def __init__(self):
        self.tables = {}
        self.current_table = None
        self.changed = False
    
    def create_table(self, name):
        if name not in self.tables:
            self.tables[name] = Table(name)
            if self.current_table is None:
                self.current_table = name
            self.changed = True
            return True
        return False
    
    def delete_table(self, name):
        if name in self.tables and name != self.current_table:
            del self.tables[name]
            self.changed = True
            return True
        return False
    
    def rename_table(self, old_name, new_name):
        if old_name in self.tables and new_name not in self.tables:
            self.tables[new_name] = self.tables.pop(old_name)
            self.tables[new_name].name = new_name
            if self.current_table == old_name:
                self.current_table = new_name
            self.changed = True
            return True
        return False
    
    def switch_table(self, name):
        if name in self.tables:
            self.current_table = name
            return True
        return False
    
    def get_current_table(self):
        if self.current_table and self.current_table in self.tables:
            return self.tables[self.current_table]
        return None
    
    def get_table_names(self):
        return list(self.tables.keys())
    
    def create_test_table(self, name="Тестовая"):
        if self.create_table(name):
            table = self.tables[name]
            table.create_test_data()
            return True
        return False
    
    def get_all_data(self):
        table = self.get_current_table()
        if table:
            return table.get_all_data()
        return {'name': None, 'columns': [], 'rows': [], 'types': {}}
    
    def get_stats(self):
        stats = {
            'total_tables': len(self.tables),
            'current': self.current_table,
            'tables': {}
        }
        for name, table in self.tables.items():
            stats['tables'][name] = table.get_stats()
        return stats