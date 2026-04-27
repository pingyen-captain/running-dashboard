-- ============================================================
-- Running Tracker — Initial Migration
-- ============================================================
-- 建立日期：2026-04-27
-- 用途：建立 runs / training_plan / weights 三張表
--       並把 index.html 60 筆歷史跑步資料 + P1 訓練計劃 + 起始體重匯入
-- 執行方式：複製整段貼到 Supabase Studio → SQL Editor → Run

-- ============================================================
-- 1. SCHEMA
-- ============================================================

-- 跑步紀錄表
CREATE TABLE IF NOT EXISTS public.runs (
  id BIGSERIAL PRIMARY KEY,
  date DATE NOT NULL,
  distance_km DECIMAL(5,2) NOT NULL,
  pace_min_per_km DECIMAL(5,2),     -- 6.83 = 6:50/km（給圖表用，小數分鐘）
  duration_seconds INT,              -- 4236 = 1:10:36
  avg_hr INT,
  max_hr INT,
  avg_power INT,                     -- 瓦
  cadence INT,                       -- 步頻 spm
  vertical_osc_cm DECIMAL(3,1),      -- 垂直振幅 cm
  ground_contact_ms INT,             -- 觸地時間 ms
  stride_length_m DECIMAL(2,1),      -- 步幅長度 m
  workout_type TEXT,                 -- 'easy', 'tempo', 'interval', 'long', 'race', 'recovery'
  notes TEXT,                        -- 感受/備註
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_runs_date ON public.runs(date DESC);

-- 訓練計劃表（每天一筆）
CREATE TABLE IF NOT EXISTS public.training_plan (
  id BIGSERIAL PRIMARY KEY,
  date DATE UNIQUE NOT NULL,
  phase TEXT,                        -- 'P1', 'P2', ..., 'trip', 'race'
  weekday TEXT,                      -- '一', '二', ..., '日'
  workout_type TEXT,                 -- 'rest', 'easy', 'tempo', 'interval', 'long', 'race', 'recovery'
  distance_target_km DECIMAL(4,1),
  pace_target TEXT,                  -- '7:00-7:15 Z2'
  hr_target TEXT,                    -- '< 143'
  gym TEXT,                          -- 'push', 'pull', 'legs', 'runner-specific'
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_training_plan_date ON public.training_plan(date);

-- 體重追蹤表
CREATE TABLE IF NOT EXISTS public.weights (
  id BIGSERIAL PRIMARY KEY,
  date DATE UNIQUE NOT NULL,
  weight_kg DECIMAL(4,1) NOT NULL,
  body_fat_pct DECIMAL(3,1),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_weights_date ON public.weights(date DESC);

-- ============================================================
-- 2. RLS POLICIES（anon 可讀，寫入限 service_role）
-- ============================================================

ALTER TABLE public.runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weights ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon read runs" ON public.runs;
CREATE POLICY "anon read runs" ON public.runs
  FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "anon read training_plan" ON public.training_plan;
CREATE POLICY "anon read training_plan" ON public.training_plan
  FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "anon read weights" ON public.weights;
CREATE POLICY "anon read weights" ON public.weights
  FOR SELECT TO anon USING (true);

-- 注意：沒有 INSERT/UPDATE/DELETE policy = anon 完全不能寫
-- 寫入只能用 service_role（在 Supabase Studio 直接執行 SQL，或 backend 用 service key）

-- ============================================================
-- 3. 歷史跑步資料（60 筆 from index.html + 1 筆 04/26 比賽）
-- ============================================================

-- 1 月（賽前訓練起點）
INSERT INTO public.runs (date, distance_km, pace_min_per_km, avg_hr, max_hr, cadence, vertical_osc_cm, ground_contact_ms, stride_length_m) VALUES
('2026-01-04', 3.97, 10.76, 133, 163, 127, 10.0, 295, 0.7),
('2026-01-07', 1.46, 11.14, 100, 128, NULL, NULL, NULL, NULL),
('2026-01-12', 1.81, 12.30, 127, 152, 111, 10.2, 320, 0.7),
('2026-01-13', 3.20, 10.76, 125, 155, 119, 10.1, 284, 0.8),
('2026-01-14', 3.23, 9.98, 132, 159, 123, 9.8, 267, 0.8),
('2026-01-15', 3.42, 9.46, 133, 157, 129, 9.5, 253, 0.8),
('2026-01-19', 3.39, 8.86, 137, 162, 127, 9.4, 232, 0.9),
('2026-01-20', 3.61, 8.63, 135, 159, 128, 9.5, 243, 0.9),
('2026-01-21', 3.39, 9.33, 137, 162, 147, 9.5, 294, 0.8),
('2026-01-22', 3.43, 8.76, 144, 167, 149, 9.5, 304, 0.7),
('2026-01-24', 3.86, 8.26, 150, 172, 151, 9.7, 299, 0.8),
('2026-01-26', 4.10, 7.54, 153, 175, 159, 9.7, 276, 0.8),
('2026-01-27', 5.07, 7.37, 156, 170, 162, 9.6, 265, 0.8),
('2026-01-28', 5.12, 6.87, 164, 174, 163, 9.7, 251, 0.8),
('2026-01-30', 6.23, 8.82, 151, 163, 140, 9.8, 278, 0.8);

-- 2 月
INSERT INTO public.runs (date, distance_km, pace_min_per_km, avg_hr, max_hr, cadence, vertical_osc_cm, ground_contact_ms, stride_length_m) VALUES
('2026-02-02', 6.03, 7.18, 161, 168, 164, 9.3, 273, 0.8),
('2026-02-03', 4.11, 8.58, 139, 146, 162, 9.8, 311, 0.7),
('2026-02-08', 6.11, 7.93, 148, 157, 165, 9.5, 290, 0.7),
('2026-02-20', 4.09, 9.67, 137, 156, 148, 10.0, 297, 0.8),
('2026-02-22', 3.03, 8.60, 139, 148, 153, 10.1, 300, 0.8),
('2026-02-23', 4.08, 8.85, 139, 151, 160, 10.0, 316, 0.7),
('2026-02-25', 4.05, 8.80, 141, 154, 159, 9.9, 309, 0.7),
('2026-02-26', 5.01, 8.43, 145, 151, 163, 9.7, 291, 0.7),
('2026-02-28', 4.00, 8.72, 144, 154, NULL, NULL, NULL, NULL);

-- 3 月（含 5K 比賽 03/28）
INSERT INTO public.runs (date, distance_km, pace_min_per_km, avg_hr, max_hr, cadence, vertical_osc_cm, ground_contact_ms, stride_length_m, workout_type, notes) VALUES
('2026-03-01', 6.12, 7.50, 150, 156, 162, 9.8, 280, 0.8, NULL, NULL),
('2026-03-03', 4.11, 7.88, 138, 156, 164, 9.8, 308, 0.7, NULL, NULL),
('2026-03-04', 5.01, 7.25, 155, 180, 156, 9.4, 275, 0.9, NULL, NULL),
('2026-03-05', 4.05, 8.03, 139, 145, 167, 9.6, 298, 0.7, NULL, NULL),
('2026-03-06', 5.02, 7.48, 151, 162, 170, 9.5, 282, 0.8, NULL, NULL),
('2026-03-07', 4.12, 7.68, 139, 145, 170, 9.5, 292, 0.7, NULL, NULL),
('2026-03-08', 7.01, 7.43, 146, 158, 169, 9.5, 290, 0.8, NULL, NULL),
('2026-03-10', 4.02, 7.28, 143, 149, 171, 9.4, 287, 0.8, NULL, NULL),
('2026-03-11', 5.03, 6.92, 152, 168, 171, 9.4, 281, 0.8, NULL, NULL),
('2026-03-12', 4.07, 7.32, 138, 149, 171, 9.4, 277, 0.9, NULL, NULL),
('2026-03-13', 5.41, 6.75, 162, 175, 168, 9.4, 266, 0.8, NULL, NULL),
('2026-03-14', 4.01, 7.13, 142, 164, 168, 9.4, 265, 0.8, NULL, NULL),
('2026-03-15', 8.06, 7.17, 151, 162, 168, 9.4, 258, 0.8, 'long', '海邊路跑，爬升 107m，3 月最長距離'),
('2026-03-17', 4.07, 7.23, 137, 143, 171, 9.4, 278, 0.9, NULL, NULL),
('2026-03-18', 5.12, 6.22, 158, 164, 175, 9.2, 237, 0.7, 'race', '5K 模擬跑 31:51'),
('2026-03-19', 4.05, 7.50, 138, 146, 172, 9.2, 270, 0.9, NULL, NULL),
('2026-03-20', 5.47, 6.78, 159, 176, 158, 9.3, 242, 0.8, NULL, '碳水不足跑到沒力'),
('2026-03-24', 3.01, 7.00, 139, 167, 174, 9.4, 268, 0.9, NULL, NULL),
('2026-03-25', 3.63, 7.98, 140, 168, 161, 9.5, 298, 0.7, NULL, NULL),
('2026-03-26', 2.02, 8.03, 138, 162, 167, 9.4, 293, 0.9, NULL, NULL),
('2026-03-28', 5.18, 6.37, 162, 178, 166, 9.5, 234, 0.7, 'race', '5K 比賽 30:49 sub-31');

-- 4 月（含 10K 比賽 04/26）
INSERT INTO public.runs (date, distance_km, pace_min_per_km, avg_hr, max_hr, cadence, vertical_osc_cm, ground_contact_ms, stride_length_m, workout_type, notes) VALUES
('2026-03-31', 4.16, 7.93, 140, 146, 164, 9.5, 293, 0.7, NULL, NULL),
('2026-04-02', 4.00, 7.72, 144, 155, 163, 9.5, 290, 0.7, NULL, NULL),
('2026-04-03', 4.14, 7.78, 139, 147, 163, 9.4, 289, 0.8, NULL, NULL),
('2026-04-06', 4.10, 7.38, 143, 150, 167, 9.4, 273, 0.8, NULL, NULL),
('2026-04-08', 5.00, 7.47, 152, 164, 164, 9.4, 276, 0.7, NULL, NULL),
('2026-04-09', 4.14, 7.97, 140, 147, 165, 9.5, 286, 0.9, NULL, NULL),
('2026-04-10', 6.37, 7.27, 151, 178, 156, 9.2, 264, 0.8, NULL, '節奏+間歇混合'),
('2026-04-11', 5.00, 7.45, 145, 152, 165, 9.3, 273, 0.8, NULL, '廈門出差'),
('2026-04-12', 10.01, 7.40, 158, 175, 159, 9.4, 257, 0.7, 'long', '人生首次 10K（廈門，爬升 85m）'),
('2026-04-13', 4.01, 7.38, 139, 147, 170, 9.3, 256, 0.8, NULL, '金門'),
('2026-04-15', 6.10, 6.77, 150, 162, 173, 9.4, 249, 0.8, 'tempo', '10K 配速跑 6:46'),
('2026-04-17', 4.50, 7.18, 140, 149, 174, 9.3, 264, 0.8, NULL, NULL),
('2026-04-18', 6.03, 6.97, 153, 175, 158, 9.3, 251, 0.8, 'interval', '間歇 1km×3'),
('2026-04-19', 12.00, 6.98, 152, 160, 171, 9.4, 266, 0.8, 'long', '12K 長跑首次 sub-7'),
('2026-04-20', 4.00, 6.83, 140, 152, 174, 9.3, 269, NULL, NULL, 'W4 減量週'),
('2026-04-26', 10.32, 6.83, 162, 178, 169, 9.2, 258, 0.8, 'race', '人生首場 10K 比賽 1:10:36，sub-70 達成');

-- ============================================================
-- 4. 體重起始紀錄
-- ============================================================

INSERT INTO public.weights (date, weight_kg, body_fat_pct, notes) VALUES
('2026-01-30', 90.6, 34.2, '健檢起始體重'),
('2026-04-27', 89.0, NULL, '半馬訓練週期啟動，目標 12/6 78 kg → 2027 Q1 75 kg');

-- ============================================================
-- 5. 訓練計劃 P1（5/1-5/31，5 週）
-- ============================================================

-- W1: 賽後恢復尾段
INSERT INTO public.training_plan (date, phase, weekday, workout_type, distance_target_km, pace_target, hr_target, gym, notes) VALUES
('2026-05-01', 'P1', '五', 'rest', NULL, NULL, NULL, NULL, '4/26 賽後第 5 天，完全休息'),
('2026-05-02', 'P1', '六', 'easy', 4.0, '7:30 Z1', '< 140', NULL, '測試身體狀態'),
('2026-05-03', 'P1', '日', 'rest', NULL, NULL, NULL, NULL, NULL);

-- W2: P1 啟動
INSERT INTO public.training_plan (date, phase, weekday, workout_type, distance_target_km, pace_target, hr_target, gym, notes) VALUES
('2026-05-04', 'P1', '一', 'easy', 5.0, '7:00-7:15 Z2', '< 143', 'push', 'P1 正式啟動！飲食記錄開始'),
('2026-05-05', 'P1', '二', 'easy', 5.0, '7:00-7:15 Z2', '< 143', NULL, NULL),
('2026-05-06', 'P1', '三', 'recovery', 4.0, '7:30 Z1', '< 135', 'legs', '膝蓋友善 Leg Day 首次'),
('2026-05-07', 'P1', '四', 'rest', NULL, NULL, NULL, NULL, NULL),
('2026-05-08', 'P1', '五', 'easy', 5.0, '7:00-7:15 Z2', '< 143', 'pull', NULL),
('2026-05-09', 'P1', '六', 'long', 8.0, '7:00-7:15 Z2', '< 145', 'runner-specific', '長跑'),
('2026-05-10', 'P1', '日', 'rest', NULL, NULL, NULL, NULL, '量體重');

-- W3: 建立節奏
INSERT INTO public.training_plan (date, phase, weekday, workout_type, distance_target_km, pace_target, hr_target, gym, notes) VALUES
('2026-05-11', 'P1', '一', 'easy', 5.0, '7:00-7:15 Z2', '< 143', 'push', NULL),
('2026-05-12', 'P1', '二', 'easy', 5.0, '7:00-7:15 Z2', '< 143', NULL, NULL),
('2026-05-13', 'P1', '三', 'recovery', 4.0, '7:30 Z1', '< 135', 'legs', NULL),
('2026-05-14', 'P1', '四', 'rest', NULL, NULL, NULL, NULL, NULL),
('2026-05-15', 'P1', '五', 'easy', 5.0, '7:00-7:15 Z2', '< 143', 'pull', NULL),
('2026-05-16', 'P1', '六', 'long', 9.0, '7:00-7:15 Z2', '< 145', 'runner-specific', NULL),
('2026-05-17', 'P1', '日', 'rest', NULL, NULL, NULL, NULL, '量體重');

-- W4: 累積基礎
INSERT INTO public.training_plan (date, phase, weekday, workout_type, distance_target_km, pace_target, hr_target, gym, notes) VALUES
('2026-05-18', 'P1', '一', 'easy', 5.0, '7:00-7:15 Z2', '< 143', 'push', NULL),
('2026-05-19', 'P1', '二', 'easy', 5.0, '7:00-7:15 Z2', '< 143', NULL, NULL),
('2026-05-20', 'P1', '三', 'recovery', 4.0, '7:30 Z1', '< 135', 'legs', NULL),
('2026-05-21', 'P1', '四', 'rest', NULL, NULL, NULL, NULL, NULL),
('2026-05-22', 'P1', '五', 'easy', 5.0, '7:00-7:15 Z2', '< 143', 'pull', NULL),
('2026-05-23', 'P1', '六', 'long', 10.0, '7:00-7:10 Z2', '< 148', 'runner-specific', NULL),
('2026-05-24', 'P1', '日', 'rest', NULL, NULL, NULL, NULL, '量體重');

-- W5: P1 收尾
INSERT INTO public.training_plan (date, phase, weekday, workout_type, distance_target_km, pace_target, hr_target, gym, notes) VALUES
('2026-05-25', 'P1', '一', 'easy', 5.0, '7:00-7:15 Z2', '< 143', 'push', NULL),
('2026-05-26', 'P1', '二', 'easy', 5.0, '7:00-7:15 Z2', '< 143', NULL, NULL),
('2026-05-27', 'P1', '三', 'recovery', 4.0, '7:30 Z1', '< 135', 'legs', NULL),
('2026-05-28', 'P1', '四', 'rest', NULL, NULL, NULL, NULL, NULL),
('2026-05-29', 'P1', '五', 'easy', 5.0, '7:00-7:15 Z2', '< 143', 'pull', NULL),
('2026-05-30', 'P1', '六', 'long', 12.0, '7:00-7:10 Z2', '< 150', 'runner-specific', 'P1 最後長跑'),
('2026-05-31', 'P1', '日', 'rest', NULL, NULL, NULL, NULL, '量體重 → 目標 86.5 kg');

-- ============================================================
-- 6. 驗證查詢（執行完後跑這幾條檢查）
-- ============================================================

-- 應該回 61
SELECT COUNT(*) AS run_count FROM public.runs;

-- 應該回 31（P1 共 31 天）
SELECT COUNT(*) AS plan_count FROM public.training_plan WHERE phase = 'P1';

-- 應該回 2
SELECT COUNT(*) AS weight_count FROM public.weights;

-- 看最近 5 筆跑步
SELECT date, distance_km, pace_min_per_km, avg_hr, workout_type, notes
FROM public.runs
ORDER BY date DESC
LIMIT 5;

-- 看下週訓練
SELECT date, weekday, workout_type, distance_target_km, pace_target, gym
FROM public.training_plan
WHERE date >= CURRENT_DATE
ORDER BY date
LIMIT 7;

-- ============================================================
-- 完成！如果驗證查詢都正確，下一步：
-- 1. 我會改寫 index.html 用 Supabase 取代寫死陣列
-- 2. 之後的訓練計劃 (P2-P8) 等接近時再陸續匯入
-- ============================================================
