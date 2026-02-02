# Dashboard 更新流程

#跑步 #維護文件

**Dashboard 網址**：https://pingyen-captain.github.io/running-dashboard/
**GitHub Repo**：https://github.com/pingyen-captain/running-dashboard

---

## 檔案位置

```
/Users/boriswu/Desktop/我的工作站/01 - 專案/跑步訓練/index.html
```

（這是 iCloud/Obsidian 的 symlink，實際路徑在 iCloud~md~obsidian）

---

## 更新流程

### 1. 用戶提供數據

用戶會貼跑步截圖或數據，包含：
- 日期
- 距離、時間、配速
- 平均心率、最高心率
- 功率、步頻（如有）
- 跑步力學數據（步頻、垂直振幅、觸地時間、步幅長度）

### 2. 更新 index.html

需要更新的區塊：

#### a. 總統計數據（stats-grid）
```javascript
// 搜尋這些數值並更新
總跑步次數、累積里程、最佳配速、最長距離、配速進步
```

#### b. 月進度（progress-section）
```javascript
// 更新 2 月進度
目標：60 km / 月
已完成：X km
剩餘：Y km
進度條 width 百分比
```

#### c. 跑步數據陣列（script 區塊）
```javascript
const dates = ['01/04', '01/07', ...];           // 加入新日期
const distances = [3.97, 1.46, ...];             // 加入新距離
const paces = [10.76, 11.14, ...];               // 加入新配速（分鐘數）
const avgHr = [133, 100, ...];                   // 加入平均心率
const maxHr = [163, 128, ...];                   // 加入最高心率
```

#### d. 跑步力學數據（如有）
```javascript
const mechanicsDates = ['01/04', '01/12', ...];  // 加入日期
const cadence = [127, 111, ...];                 // 步頻 spm
const verticalOsc = [10.0, 10.2, ...];           // 垂直振幅 cm
const groundContact = [295, 320, ...];           // 觸地時間 ms
const strideLength = [0.7, 0.7, ...];            // 步幅長度 m
```

#### e. 今日訓練數據（trainingSchedule）
如果訓練計劃有變動，更新 `trainingSchedule` 物件。

### 3. 推送到 GitHub

```bash
cd /Users/boriswu/Desktop/我的工作站/01\ -\ 專案/跑步訓練
git add index.html
git commit -m "更新跑步數據 MM/DD"
git push
```

### 4. 等待部署

GitHub Pages 約 1-2 分鐘自動部署完成。

---

## 同步更新 Obsidian 文件

### 跑步日誌.md
新增當日跑步記錄（格式參考現有記錄）

### 2026-02-跑步數據分析.md
更新月度統計和跑步記錄表格

---

## 配速轉換

配速格式轉換（表格顯示 vs 計算用）：
- 7:11 min/km → 7.18（分鐘數）
- 計算方式：分鐘 + 秒數/60
- 例：7:11 = 7 + 11/60 = 7.183

---

## 注意事項

1. **日期格式**：陣列中用 `'MM/DD'` 格式
2. **配速數值**：用分鐘數（小數），不是 `'7:11'` 字串
3. **順序**：新數據加在陣列最後
4. **跑步力學**：不是每次都有，只有有記錄的日期才加

---

*建立日期：2026-02-02*
