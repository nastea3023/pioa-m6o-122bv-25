#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Запускатор проекта "Консольная БД с множественными таблицами"
Просто запусти этот файл: python start.py
"""

import sys
import os

sys.path.append(os.path.dirname(__file__))

from frontend.console import ConsoleUI

def main():
    print("╔════════════════════════════════════════════╗")
    print("║    КОНСОЛЬНАЯ БАЗА ДАННЫХ v3.0            ║")
    print("║         (Множественные таблицы)           ║")
    print("╚════════════════════════════════════════════╝")
    print("\nЗагрузка...\n")
    
    app = ConsoleUI()
    app.run()

if __name__ == "__main__":
    main()