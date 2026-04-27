# Dashboard 更新流程（Supabase 版）

#跑步 #維護文件

> 最後更新：2026-04-27
> 架構升級：從 HTML 寫死陣列 → Supabase 動態載入

---

## 系統架構

```
[你 — Apple Watch 截圖]
        ↓
[Claude — 從圖讀數據 + 寫 SQL]
        ↓
[你 — 貼 SQL 到 Supabase Studio Run]
        ↓
[Supabase — runs / training_plan / weights 表]
        ↓
[Dashboard — fetch + 渲染圖表]
```

---

## 重要連結

| 項目 | URL |
|------|-----|
| **Dashboard** | https://pingyen-captain.github.io/running-dashboard/ |
| **GitHub Repo** | https://github.com/pingyen-captain/running-dashboard |
| **Supabase Studio** | https://supabase.com/dashboard/project/shbglvknbzczzougqhko |
| **本地 HTML** | `/Users/boriswu/Desktop/我的工作站/01 - 專案/跑步訓練/index.html` |

---

## 工作流程：每次跑步後

### Step 1：你 — 傳截圖給 Claude

打開 Claude，傳 Apple Watch 跑步詳情截圖（**體能訓練詳細資訊**整頁）。

包含這些資料的截圖最完整：
- 地圖 + 距離 + 時間
- 心率 + 配速
- 步頻 + 垂直振幅 + 觸地時間 + 步幅長度
- 功率（如有）

可選附上一句話描述：「今天輕鬆跑、感覺 OK」/ 「腳有點痠」

### Step 2：Claude — 抓資料 + 寫 SQL

Claude 會：
1. 從截圖讀出所有數據
2. 更新 `跑步日誌.md`（含感受/分析的 narrative）
3. 給你一段 INSERT SQL，例如：

```sql
INSERT INTO public.runs
  (date, distance_km, pace_min_per_km, avg_hr, max_hr, cadence,
   vertical_osc_cm, ground_contact_ms, stride_length_m,
   workout_type, notes)
VALUES
  ('2026-05-04', 5.02, 7.05, 142, 156, 168, 9.4, 275, 0.8,
   'easy', 'P1 W2 第一天，膝蓋無不適');
```

### Step 3：你 — 貼到 Supabase Studio

1. 打開 https://supabase.com/dashboard/project/shbglvknbzczzougqhko
2. 左側 menu → **SQL Editor**
3. 點 **New query** 或用既有的 query
4. 貼上 Claude 給的 SQL
5. 按 **Run**（Cmd+Enter）
6. 看到 `Success. No rows returned` = OK ✅

### Step 4：自動更新

Dashboard 會在下次 reload 時自動撈最新資料。

---

## 工作流程：每週一量體重後

### Step 1：你 — 量完傳數字給 Claude

每週一早上空腹量完，傳訊息：「今天 87.3 kg」

### Step 2：Claude 給 INSERT SQL

```sql
INSERT INTO public.weights (date, weight_kg, notes)
VALUES ('2026-05-04', 87.3, 'P1 W2 起點');
```

### Step 3：你貼 Studio 跑

同上。

---

## 工作流程：訓練計劃 P2-P8 階段交替時

每進入新階段（5/31 P1→P2、7/5 P2→P3 等），Claude 會給一份大的 training_plan INSERT SQL，把該階段所有日課表一次匯入。

例如進入 P2 時：

```sql
-- P2: 6/1-7/5 共 35 天
INSERT INTO public.training_plan
  (date, phase, weekday, workout_type, distance_target_km,
   pace_target, hr_target, gym, notes)
VALUES
  ('2026-06-01', 'P2', '一', 'easy', 5.0, '7:00-7:15 Z2', '< 143', 'push', NULL),
  ('2026-06-02', 'P2', '二', 'tempo', 6.0, '熱身 1km + 4km @ 6:10 + 緩和 1km', '155-165', NULL, 'Tempo 入門'),
  -- ... 35 天 ...
;
```

你貼 Studio 跑一次就完成。

---

## Schema 速查

### `runs` 表
| 欄位 | 型別 | 說明 | 範例 |
|------|------|------|------|
| `date` | DATE | 跑步日期 | '2026-04-26' |
| `distance_km` | DECIMAL | 距離（公里） | 10.32 |
| `pace_min_per_km` | DECIMAL | 配速（分鐘小數） | 6.83（= 6:50） |
| `duration_seconds` | INT | 總秒數（可選） | 4236 |
| `avg_hr` | INT | 平均心率 | 162 |
| `max_hr` | INT | 最高心率 | 178 |
| `avg_power` | INT | 平均功率 W | 222 |
| `cadence` | INT | 步頻 spm | 169 |
| `vertical_osc_cm` | DECIMAL | 垂直振幅 cm | 9.2 |
| `ground_contact_ms` | INT | 觸地時間 ms | 258 |
| `stride_length_m` | DECIMAL | 步幅長度 m | 0.8 |
| `workout_type` | TEXT | 課表類型 | 'easy', 'tempo', 'interval', 'long', 'race', 'recovery' |
| `notes` | TEXT | 感受/備註 | '人生首場 10K' |

### `training_plan` 表
| 欄位 | 說明 |
|------|------|
| `date` | 日期（unique）|
| `phase` | 'P1', 'P2', ..., 'P8', 'trip' |
| `weekday` | '一', '二', ..., '日' |
| `workout_type` | 'rest', 'easy', 'tempo', 'interval', 'long', 'race', 'recovery' |
| `distance_target_km` | 目標距離 |
| `pace_target` | 配速目標（字串）'7:00-7:15 Z2' |
| `hr_target` | 心率目標（字串）'< 143' |
| `gym` | 'push', 'pull', 'legs', 'runner-specific' |
| `notes` | 備註 |

### `weights` 表
| 欄位 | 說明 |
|------|------|
| `date` | 量體重日期（unique）|
| `weight_kg` | 體重 kg |
| `body_fat_pct` | 體脂率（可選） |
| `notes` | 備註 |

---

## 配速轉換速查

Apple Watch 顯示 → 資料庫存的小數：

| 顯示 | pace_min_per_km |
|------|-----------------|
| 5:30 | 5.50 |
| 5:45 | 5.75 |
| 6:00 | 6.00 |
| 6:23 | 6.38 |
| 6:48 | 6.80 |
| 6:50 | 6.83 |
| 7:00 | 7.00 |
| 7:15 | 7.25 |
| 7:30 | 7.50 |

公式：`小數 = 分 + 秒/60`
- 6:50 → 6 + 50/60 = 6.833
- 6:23 → 6 + 23/60 = 6.383

---

## 故障排除

### Dashboard 沒更新
1. 開 Console（Cmd+Option+I）→ Console tab
2. 看是否有 error（紅字）
3. 如果看到 `Loaded: 0 runs` → Supabase 連線/權限問題
4. 如果看到正確 `Loaded: N runs` 但圖表沒更新 → Cmd+Shift+R 強制重新整理

### SQL 執行失敗
- **`duplicate key value violates unique constraint`** → date 已存在，改用 `INSERT ... ON CONFLICT (date) DO UPDATE` 或先 DELETE
- **`column "xxx" does not exist`** → schema 不對，檢查欄位名
- **`new row violates row-level security policy`** → 用了 anon key 寫入，必須在 Studio 裡執行（Studio 用 service_role）

### 想修改某筆跑步資料
```sql
UPDATE public.runs
SET avg_hr = 165, notes = '更正：HR 重新確認'
WHERE date = '2026-04-26';
```

### 想刪掉某筆
```sql
DELETE FROM public.runs WHERE date = '2026-04-26';
```

---

## 相關檔案

- [[2026-12-新竹半馬訓練計劃]] — 32 週主訓練計劃
- [[跑步日誌]] — 每次跑步的 narrative 記錄
- [[Gemini-每日飲食估算Prompt]] — Gemini 飲食追蹤 prompt
- [[2026-健康管理計劃]] — 整體健康策略
- `supabase-migration.sql` — 初始 migration（5/1 已跑）
- `2026-半馬訓練行事曆.ics` — 行事曆事件（已匯入 Calendar）

---

*建立日期：2026-02-02*
*Supabase 升級：2026-04-27*
