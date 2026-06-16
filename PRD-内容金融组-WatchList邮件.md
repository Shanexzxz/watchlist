# PRD ｜内容金融组 · 每日 Watch List 邮件

> 产品需求文档  
> 版本：v0.1（草稿）｜最后更新：2026-06-15｜负责人：产品（Shayn）

---

## 0. 文档怎么用（给协作同学）

- 本文是**产品需求**，不是技术实现文档。前端、后端看完应能各自独立开工。
- 仓库里附带的 `generate.py`、`content-finance-daily.html` 等文件**仅为产品经理制作的视觉/数据原型（demo）**，用来表达"最终长什么样、有哪些字段"。**正式实现不复用这些文件**，但应严格对齐其呈现效果与字段含义。

---

## 1. 背景与目标

内容金融组（投资并购部）需要每个交易日向相关同事发送一封 **二级市场持仓 Watch List 邮件**：以邮件友好的 HTML 表格，展示组内关注标的当日行情、估值，以及内部持仓信息（MA 持有价值、MoC、模拟仓、TPP 持仓标记）。  
每交易日定时从数据源取数 → 渲染 HTML → 邮件发送，全流程自动化。

### 目标

1. 数据自动化：行情类数据来自 **Bloomberg**，持仓类数据来自 **TIM**，无需人工填值。
2. 渲染标准化：前端按统一数据契约渲染邮件 HTML，视觉对齐 demo。
3. 发送自动化：每交易日上午 9 点定时发送 T-1 的数据，收件人可配置（一个行业组一封）。

### 非目标（本期不做）

- 不做交互式网页（这是一封**只读邮件**，不是 Web 应用）。

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
│ 1. ...  2. ...  3. ...（编号脚注列表，含 * = TPP 说明）   │ ← 脚注
└─────────────────────────────────────────────────────────┘
```

- 标的按 **行业分类**（`【XXX】`）分组，每组一张表。
- **指数表** 在最前，列结构比行业表少（无持仓相关后 3 列），每个组的指数不一样，详见 excel。
- **TPP 有持仓** 的公司，公司名后加金色 `*` 角标，并在脚注说明。
- **顶部摘要 bullets**：监控市值涨跌幅 >5% 的股票，列出当日涨幅或跌幅超过 5% 的标的（如 `XXX (+8%), YYY (-6%)`）。

---

## 4. 字段字典

### 4.1 行业表（每只标的 12 列）

| # | 列名 | 含义 | 数据源 | 示例 / 格式 |
|---|---|---|---|---|
| 1 | 公司 | 公司名（TPP 持仓加 `*`） | TIM | `Netflix *` |
| 2 | {日期} | 当日收盘价（带币种） | Bloomberg | `USD 97.54` / `HKD 23.46` |
| 3 | Change | 当日涨跌幅 | Bloomberg | `+2.1%`（绿）/ `-1.1%`（红） |
| 4 | Turnover (USD'000) | 当日成交额（千分位，单位千美元） | Bloomberg | `1,846,423` |
| 5 | Adj. P/E (2026E) | 2026 预测市盈率 | Bloomberg | `28.5x` |
| 6 | Mkt Cap (USD M) | 市值（百万美元） | Bloomberg | `45,200` |
| 7 | Price Change (YTD) | 年初至今涨跌幅 | Bloomberg | `+12%` |
| 8 | Price Change (L30D) | 近 30 日涨跌幅 | Bloomberg | `+3%` |
| 9 | Price Change (L365D) | 近 365 日涨跌幅 | Bloomberg | `+48%` |
| 10 | MA 持有价值 (USD M) | 投后持有价值（百万美元） | TIM | `1,500.50` |
| 11 | MoC | Multiple of Capital（含 CB 不含减值） | TIM | `1.25x` |
| 12 | 模拟仓 | 该 ticker 是否在 TIM 模拟仓中 | TIM | `Y` / `N` |

> **MA 持有价值、MoC、模拟仓、TPP 持仓标记** 均来自 TIM；**其余所有市场/行情/估值数据** 均来自 Bloomberg。

### 4.2 指数表（9 列）

仅含上表 **第 1–9 列**（无 MA 持有价值 / MoC / 模拟仓）。首列为指数名，价格/Turnover 等指数无对应值的填 `-`。

---

## 5. 底部备注 / 脚注样式

底部区域自上而下两部分：

**① Source 行**
```
Source: Bloomberg, TIM
```
- 紧跟最后一张表格下方，黑字、左对齐、加粗 `Source:` 前缀。

**② 编号脚注列表（Footnotes）**
- 黑字白底、**左对齐、垂直排列**，与表格之间留明显间距。
- 每条以 **数字序号 + `.`** 开头（`1.` `2.` `3.` …），逐条说明。
- 字号 11px，行高放宽（约 1.6–1.7）以便阅读。
- 顶部用 `#ccc` 1px 细线与表格分隔。

脚注示例条目：

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
