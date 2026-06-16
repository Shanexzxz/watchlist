# Watchlist · 邮件项目

> 投资并购部 · 内容金融组每日 Watch List 邮件  
> 完整产品需求见 [`PRD-内容金融组-WatchList邮件.md`](./PRD-内容金融组-WatchList邮件.md)

## 用途

每交易日推送一封 HTML 邮件，展示内容金融组关注标的的当日行情 + 持仓信息。

## 文件结构

| 文件 | 用途 |
|---|---|
| `PRD-内容金融组-WatchList邮件.md` | **产品需求（源头）** — 字段定义、视觉规范、数据源 |
| `content-finance-daily.html` | 视觉/数据 demo — 前端对齐此样式 |
| `generate.py` | Demo 生成脚本（仅供产品经理做原型用，工程化时重写） |

## 视觉对齐

前端邮件样式 **必须严格遵循** `content-finance-daily.html` 的呈现，包括：
- 蓝白交替行（`#fff` / `#C6D9F1`）
- 黑色 1px 细边框
- 涨绿 `#006400` / 跌红 `#c00`
- 金色 `*` 标记 TPP 持仓

任何视觉调整先对比 demo。
