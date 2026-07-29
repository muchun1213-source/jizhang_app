-- Supabase 建表 SQL：在 Supabase SQL Editor 中执行
-- 打开 https://supabase.com/dashboard → 你的项目 → SQL Editor → 粘贴并执行

-- 1. 分类表（与本地 categories 表对应）
CREATE TABLE categories (
  id          INTEGER PRIMARY KEY,
  name        TEXT NOT NULL,
  parent_id   INTEGER,
  icon        TEXT,
  type        TEXT NOT NULL DEFAULT 'expense',
  sort_order  INTEGER NOT NULL DEFAULT 0
);

-- 2. 记账记录表（与本地 expenses 表对应）
CREATE TABLE expenses (
  id           INTEGER PRIMARY KEY,
  amount       REAL NOT NULL,
  category_id  INTEGER NOT NULL REFERENCES categories(id),
  note         TEXT,
  expense_date TIMESTAMPTZ NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL
);

-- 3. 开启 RLS（行级安全），允许匿名读写
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all on categories"
  ON categories FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow all on expenses"
  ON expenses FOR ALL
  USING (true)
  WITH CHECK (true);
