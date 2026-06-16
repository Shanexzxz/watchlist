# PRD ｜内容金融组 · 每日 Watch List 邮件

> 产品需求 + 前后端协作规格说明
> 版本：v0.1（草稿）｜最后更新：2026-06-15｜负责人：产品（Shayn）

---

## 0. 文档怎么用（给协作同学）

- 本文是**产品需求 + 接口契约**，不是技术实现文档。前端、后端看完应能各自独立开工。
- 仓库里附带的 `generate.py`、`content-finance-daily.html` 等文件**仅为产品经理制作的视觉/数据原型（demo）**，用来表达"最终长什么样、有哪些字段"。**正式实现不复用这些文件**，但应严格对齐其呈现效果与字段含义。
- 全文凡标注 **🟡 待确认** 的，是需要产品/业务进一步拍板的点，已汇总在 [§9 待确认清单](#9-待确认清单)。

---

## 1. 背景与目标

内容金融组（投资并购部）需要每个交易日向相关同事发送一封 **二级市场持仓 Watch List 邮件**：以邮件友好的 HTML 表格，展示组内关注标的当日行情、估值，以及内部持仓信息（MA 持有价值、MoC、模拟仓、TPP 持仓标记）。
**需要工程化为一条自动流程**：每交易日定时从数据源取数 → 渲染 HTML → 邮件发送。

### 目标

1. 数据自动化：行情类数据来自 **Bloomberg**，持仓类数据来自 **TIM**（内部投资管理系统），无需人工填值。
2. 渲染标准化：前端按统一数据契约渲染邮件 HTML，视觉对齐 demo。
3. 发送自动化：每交易日上午9点定时发送T-1的数据，收件人可配置（一个行业组一封）。

### 非目标（本期不做）

- 不做交互式网页（这是一封**只读邮件**，不是 Web 应用）。


---


---

## 3. 最终形态（邮件长什么样）

参考 demo 文件 `content-finance-daily.html`。整体自上而下：

```
┌─────────────────────────────────────────────────────────┐
│ 【内容金融组】Watch list on Jun 12, 2026                  │ ← 标题（含日期）
├─────────────────────────────────────────────────────────┤
│ • Market cap over USD10 billion (rose/declined >5%): ...  │ ← 摘要 bullets
│ • Market cap under USD10 billion (rose/declined >10%): ...│
│ • Upcoming Earnings (HKT): ...                            │
├─────────────────────────────────────────────────────────┤
│ 指数表（FinTech 主题指数，9 列）                           │
├─────────────────────────────────────────────────────────┤
│ 【电子银行和钱包】 / 【信贷】 / 【券商和交易所】 ...        │ ← 按行业分多张表
│   每只标的 12 列                                           │
├─────────────────────────────────────────────────────────┤
│ Source: Bloomberg, TIM                                    │ ← 数据来源行
│ 1. ...  2. ...  3. ...（编号脚注列表，含 * = TPP 说明）   │ ← 脚注（样式见 §7.1）
└─────────────────────────────────────────────────────────┘
```

- 标的按 **行业分类**（`【XXX】`）分组，每组一张表。
- **指数表** 在最前，列结构比行业表少（无持仓相关后 3 列），每个组的指数不一样，详见excel；
- **TPP 有持仓** 的公司，公司名后加金色 `*` 角标，并在脚注说明。

**顶部摘要 bullets（后端自动生成）**：规则为**监控市值涨跌幅 >5% 的股票** —— 列出当日涨幅或跌幅超过 5% 的标的（如 `XXX (+8%), YYY (-6%)`）。
 Upcoming Earnings ：看下bbg 能否获取到earning call的数据，我在同步调研数据中台他们的数据源看看能不能复用；

---

## 4. 字段字典

### 4.1 行业表（每只标的 12 列）

| # | 列名 | 含义 | 数据源 | 示例 / 格式 |
|---|---|---|---|---|
| 1 | 公司 | 公司名（TPP 持仓加 `*`） | TIM（名称）/ TIM（TPP 标记） | `Netflix *` |
| 2 | {日期} | 当日收盘价（带币种） | **Bloomberg** | `USD 97.54` / `HKD 23.46` |
| 3 | Change | 当日涨跌幅 | **Bloomberg** | `+2.1%`（绿）/ `-1.1%`（红） |
| 4 | Turnover (USD'000) | 当日成交额（千分位，单位千美元） | **Bloomberg** | `1,846,423` |
| 5 | Adj. P/E (2026E) | 2026 预测市盈率 | **Bloomberg** | `28.5x` |
| 6 | Mkt Cap (USD M) | 市值（百万美元） | **Bloomberg** | `45,200` |
| 7 | Price Change (YTD) | 年初至今涨跌幅 | **Bloomberg** | `+12%` |
| 8 | Price Change (L30D) | 近 30 日涨跌幅 | **Bloomberg** | `+3%` |
| 9 | Price Change (L365D) | 近 365 日涨跌幅 | **Bloomberg** | `+48%` |
| 10 | MA 持有价值 (USD M) | 投后持有价值（百万美元） | **TIM** | `1,500.50` |
| 11 | MoC | Multiple of Capital（含 CB 不含减值） | **TIM** | `1.25x` |
| 12 | 模拟仓 | 该 ticker 是否在 TIM 模拟仓中 | **TIM** | `Y` / `N` |

### 4.2 指数表（9 列）

仅含上表 **第 1–9 列**（无 MA 持有价值 / MoC / 模拟仓）。首列为指数名，价格/Turnover 等指数无对应值的填 `-`。

### 4.3 数据来源汇总（重点）

| 字段 | 来源 | 备注 |
|---|---|---|
| **MA 持有价值、MoC** | **TIM**（内部投资管理系统） | 持仓估值类 |
| **模拟仓 (Y/N)** | **TIM** | 若 ticker 存在于 TIM 模拟仓 → `Y`，否则 `N` |
| **TPP 持仓标记** | **TIM** | 若 ticker 在 TIM TPP 持仓中 → 公司名加 `*` |
| **其余所有市场/行情/估值数据** | **Bloomberg** | 价格/Change/Turnover/P-E/MktCap/YTD/L30D/L365D/指数 |


---




## 6. Bloomberg & TIM 取数映射（仅供参考，实施时需再double check下）

### 6.1 Bloomberg 字段映射（参考）

> 接入方式（BLPAPI / Server API / B-PIPE / Data License）由后端按公司实际授权确定。以下为常见 field mnemonic 参考。

| 契约字段 | Bloomberg Field（参考） | 说明 |
|---|---|---|
| `price` | `PX_LAST` | 最新/收盘价 |
| `currency` | `CRNCY` | 交易币种 |
| `changePct` | `CHG_PCT_1D` | 当日涨跌幅 % |
| `turnover` | `TURNOVER` / `PX_VOLUME × PX_LAST` | 成交额；注意折算为 USD'000 |
| `peForward2026` | `BEST_PE_RATIO`（指定 fiscal year 2026）| 预测 P/E，需设预测年度 override |
| `mktCapUsdM` | `CUR_MKT_CAP` | 市值，折算为百万美元 |
| `priceChgYtdPct` | `CHG_PCT_YTD` | 年初至今 |




### 6.2 TIM 取数（给后端）

| 契约字段 | TIM 来源 | 逻辑 |
|---|---|---|
| `maHoldingUsdM` | TIM 持仓 | 投后持有价值（USD M） |
| `moc` | TIM 持仓 | MoC（含 CB、不含减值） |
| `isSimPortfolio` | TIM 模拟仓 | **若 ticker ∈ TIM 模拟仓 → true，否则 false** |
| `isTpp` | TIM TPP 持仓 | **若 ticker ∈ TIM TPP 持仓 → true**，true 则公司名加 `*`（脚注列出） |

🟡 待确认：TIM 的接入方式（API / 数据库 / 导出文件）、ticker 与 BBG 代码的对应关系（是否需要映射表）。

---

### 7.1 底部备注 / 脚注样式（更新）

> **不再使用 demo 里那条简单的金色 `*` 单句备注**，改用下图所示的「数据来源 + 编号脚注列表」规范样式（参见产品提供的样式参考图）。

底部区域自上而下两部分：

**① Source 行**
```
Source: Bloomberg, TIM
```
- 紧跟最后一张表格下方，黑字、左对齐、加粗 `Source:` 前缀。

**② 编号脚注列表（Footnotes）**
- 黑字白底、**左对齐、垂直排列**，与表格之间留明显间距。
- 每条以 **数字序号 + `.`** 开头（`1.` `2.` `3.` …），逐条说明，便于定位引用。
- 字号 11px，行高放宽（约 1.6–1.7）以便阅读。
- 顶部用 `#ccc` 1px 细线与表格分隔。

脚注**示例条目**：

```
Source: Bloomberg, TIM

1. Above data were sourced as at 7:00 am on Jun 12, 2026 (HKT).
2. Adjusted P/E ratios are based on EPS ex extraordinary items for calendar year 2026E.
3. Dual-listed company: market capitalisation of secondary listing is calculated with
   shares outstanding implied by the primary listing.
4. For companies newly listed in 2026, L365D / YTD price changes were marked as n.a.
   due to data unavailability.
5. * marks companies in which TPP holds a position (per TIM).
```

> 视觉上对齐产品提供的参考截图：黑字、白底、数字编号、左对齐的多行脚注列表。`*` TPP 标记的说明并入脚注列表的一条（不再单独成段）。




