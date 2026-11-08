# Практична робота 9.2: Варіант 2: E-Commerce Product Catalog з SQLite

Мета
Створити каталог продуктів з категоріями (hierarchical), reviews, ratings, та shopping cart через
складні JOIN queries.

## Database Schema (Схема бази даних)

### 1. `journal_entries`
- `id`: INTEGER (PRIMARY KEY AUTOINCREMENT)
- `title`: TEXT
- `content`: TEXT
- `mood`: TEXT
- `created_at`: TEXT
- `updated_at`: TEXT
- `is_favorite`: INTEGER (0 або 1)
- `word_count`: INTEGER

### 2. `tags`
- `id`: INTEGER (PRIMARY KEY AUTOINCREMENT)
- `name`: TEXT (UNIQUE)
- `color`: TEXT (Hex-код)
- `created_at`: TEXT

### 3. `entry_tags` (Many-to-Many junction table)
- `entry_id`: INTEGER (FOREIGN KEY)
- `tag_id`: INTEGER (FOREIGN KEY)

### Індекси
- `idx_entries_created_at` на `journal_entries(created_at)`
- `idx_entries_mood` на `journal_entries(mood)`
- `idx_tags_name` на `tags(name)`
