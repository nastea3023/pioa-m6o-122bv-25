class Sorter:
    @staticmethod
    def sort_by_column(data, column, reverse=False):
        """Сортировка по указанному столбцу"""
        if column not in data['columns']:
            return data
        
        # Сортируем строки
        sorted_rows = sorted(
            data['rows'], 
            key=lambda x: x.get(column), 
            reverse=reverse
        )
        
        return {
            'columns': data['columns'],
            'rows': sorted_rows
        }
    
    @staticmethod
    def sort_multiple_columns(data, columns):
        """Сортировка по нескольким столбцам"""
        if not all(col in data['columns'] for col in columns):
            return data
        
        def sort_key(row):
            return tuple(row.get(col) for col in columns)
        
        sorted_rows = sorted(data['rows'], key=sort_key)
        
        return {
            'columns': data['columns'],
            'rows': sorted_rows
        }
    
    @staticmethod
    def filter_by_value(data, column, value):
        """Фильтрация по значению"""
        if column not in data['columns']:
            return data
        
        filtered_rows = [
            row for row in data['rows'] 
            if row.get(column) == value
        ]
        
        return {
            'columns': data['columns'],
            'rows': filtered_rows
        }