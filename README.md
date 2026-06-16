# 内容金融组 · Watch list 邮件项目

> 投资并购部 · 二级市场持仓日报邮件模板  
> 最后更新：2026-06-15

## 项目目标

将 Excel 中的内容金融组持仓清单，按邮件友好的 HTML 格式渲染为每日 watch list，发送给相关同事。  
风格参照 Daniel 团队过往发出的英文 watch list 邮件（蓝白交替行 + 黑色细分割线 + 金色 `*` 标注 TPP 持仓）。

---

## 文件结构

```
email-templates/
├── README.md                          # 本文档
├── content-finance-daily.html         # ⭐ 当前最新产出（每日 watch list）
├── generate.py                        # ⭐ 数据 → HTML 的生成脚本（Python 3.9+）
├── focus-shot-quotes-jun2-2026.html   # 早期参考样本（已废弃，仅作视觉参考）
└── market-email-builder.html          # 早期多市场构建器（已废弃）
```

---

## 数据源

### 1. 持仓清单（结构化数据）
- **路径**：`/Users/shaynzhang/Desktop/1-二级/1资本组需求/3-daniel watchlist/demo-内容金融.xlsx`
- **Sheet**：`Sheet1`
- **列结构**：
  | 列 | 字段 | 示例 |
  |---|---|---|
  | A | BBG 代码 | `NFLX US Equity` |
  | B | 公司名 | `Netflix` |
  | C | MA 持有价值（USD M） | `1500.50` |
  | D | MoC（含 CB 不含减值） | `1.25` |
  | E | TPP 持仓 | `Y` / `N` / 空 |
  | F | 模拟仓 | `Y` / `N` / 空 |
- **分类**：以「`【XXX】`」包裹的中文分类标签作为行内分隔符（如 `【电子银行和钱包】`、`【信贷】`），出现在新的章节开始处
- **指数**：第 2–5 行的「`【指数】`」区下方为 4 只指数（FinTech 主题指数），首列即指数名

### 2. 行情数据（实时/历史）
- **优先源**：[WeStock Data](https://www.codebuddy.cn) — 港股 6 只 + 美股 ~67 只 6/12 收盘数据（价格、Change、Turnover）
- **次选源**：[通达信 MCP](tdx-connector) — 补充 3 只未覆盖美股（GEMI、LPLA、PICS）
- **不覆盖**：日股、韩股、伦敦、阿姆斯特丹、波兰、加密货币 — 这些市场 Change/Turnover 一律填 `-`
- **不获取**：P/E、Mkt Cap、YTD/L30D/L365D（暂未接入，按 `c × 系数` 公式伪随机生成，标注「模拟数据」）

---

## 邮件结构

```
┌─────────────────────────────────────────────────┐
│ 【内容金融组】Watch list on Jun 12, 2026         │ ← 标题
│ 暂未获取到市值，以下为模拟数据                    │ ← 灰字斜体小标
├─────────────────────────────────────────────────┤
│ • Market cap over USD10 billion (...)           │ ← 3 点摘要
│ • Market cap under USD10 billion (...)          │
│ • Upcoming Earnings (HKT) ...                  │
├─────────────────────────────────────────────────┤
│ 指数表（10 列，无 MA/MoC/TPP/模拟仓 后 4 列）    │
├─────────────────────────────────────────────────┤
│ 电子银行和钱包  / 信贷  / 券商和交易所 ...       │ ← 行业表
│ （每只标的：12 列统一列宽）                      │
├─────────────────────────────────────────────────┤
│ 备注：* 位TPP有持仓公司（联易融、Netflix）       │ ← 脚注
└─────────────────────────────────────────────────┘
```

### 12 列统一结构（行业表）

| # | 列 | 说明 |
|---|---|---|
| 1 | 公司 | 含 `*` 标记 TPP 持仓 |
| 2 | 12-Jun | 股价绝对值（`HKD 23.46` / `USD 97.54`） |
| 3 | Change | 涨跌幅（绿涨红跌） |
| 4 | Turnover (USD'000) | 成交额（千分符，**已除以 1000**） |
| 5 | Adj. P/E (2026E) | 暂填 `-` |
| 6 | Mkt Cap (USD M) | 暂填 `-` |
| 7 | Price Change (YTD) | 模拟 |
| 8 | Price Change (L30D) | 模拟 |
| 9 | Price Change (L365D) | 模拟 |
| 10 | MA 持有价值 (USD M) | Excel 真实值 |
| 11 | MoC | Excel 真实值 |
| 12 | 模拟仓 | 仍保留该列（Y/N/-）作为内部参考 |

> 指数表只有前 9 列（无 MA/MoC/模拟仓）。

---

## 视觉规范

| 元素 | 颜色 | 备注 |
|---|---|---|
| 表头底 | `#e8e8e8` | 灰底白字 |
| 数据行（奇数） | `#fff` | 白底 |
| 数据行（偶数） | `#C6D9F1` | 浅蓝底 |
| 边框线 | `#000` | 1px 实线 |
| 涨色 | `#006400` | 深绿 |
| 跌色 | `#c00` | 中红 |
| NA 占位 | `#999` | 浅灰 |
| TPP `*` 角标 | `#B8860B` | 金色加粗 |
| 脚注线 | `#ccc` | 1px 浅灰 |

**字体**：Arial / Helvetica Neue / Microsoft YaHei（中文兜底）  
**正文字号**：12px；表头 11px  
**行高**：1.5；表内行 5px padding

---

## 如何重新生成

```bash
cd "/Users/shaynzhang/WorkBuddy/watch list/email-templates"
python3 generate.py
```

脚本会：
1. 读取 `demo-内容金融.xlsx`（路径硬编码在脚本顶部 `PATH` 常量）
2. 合并硬编码的 `R` 字典（WeStock + TDX 6/12 真实行情）
3. 输出覆盖 `content-finance-daily.html`

### 更新数据

**改日期** → 改脚本顶部的 `DATE` / `TITLE` 常量  
**改真实行情** → 更新 `R` 字典中的 `{p, c, a}`（p=价格, c=涨跌幅, a=成交额 USD'000）  
**加新行业** → 在 Excel 中新增 `【XXX】` 区块即可，无需改代码  
**加新列** → 修改 `idx_hdrs` / `stk_hdrs` 列表 + `idx_row` / `stk_row` 函数

### 接入新数据源

如果要替换 WeStock，修改 `gp()` / `gc()` / `ga()` 三个 lookup 函数即可。  
接入顺序：WeStock → TDX → 兜底 `-`。

---

## 已知限制

1. **YTD/L30D/L365D 是模拟**（基于当日 Change × 系数），暂未接入历史数据 API
2. **日韩股/欧股/加密** — Change / Turnover 一律 `-`，未来可考虑接入 Bloomberg / Refinitiv
3. **真实行情是硬编码** — 没有 live fetch，每次都要手动更新 `R` 字典；下一步可用 cron + WeStock 自动化
4. **P/E、Mkt Cap 缺失** — Excel 中无此字段，邮件开头有「暂未获取到市值，以下为模拟数据」提示

---

## 待办（Roadmap）

- [ ] 接入历史 K 线 → YTD/L30D/L365D 真实值
- [ ] 日股/韩股数据源调研（Bloomberg BDP / Refinitiv / 雅虎财经）
- [ ] 自动化：每日 9:00 跑 `generate.py` → 输出到 iCloud / Notion / 邮件
- [ ] 邮件客户端适配：Outlook / Gmail 是否会破坏 inline 样式
- [ ] 支持多个 watch list（不只内容金融组，也支持其他组）

---

## 协作约定

- **修改数据**：直接改 `demo-内容金融.xlsx`，然后跑 `python3 generate.py`
- **修改视觉**：改 `generate.py` 中的 CSS 段（`<style>...</style>`），保持与上方「视觉规范」表一致
- **新增列**：必须同步更新「邮件结构」表格和「统一列结构」表格
- **任何破坏视觉规范的修改**：先在 PR 描述里说明原因

---

## 维护者

- 主要：Daniel（投资并购部）
- 数据源支持：WeStock Data、通达信 MCP
- 历史参考样本：`focus-shot-quotes-jun2-2026.html`（2026-06-15 截取）
