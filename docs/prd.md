# 策略管理与迭代系统 PRD
版本：v2.0 | 状态：Draft | 作者：PM | 日期：2026-05-05
Appetite：Big Batch 6 周
范围模式：SELECTIVE EXPANSION（基线 + 可选扩展）
信号强度：假设 [未验证假设]

---

## 0. 决策摘要（给忙碌的人看）

**一句话**：为个人投资者，解决"选股策略单一、无法评估策略效果、策略不会随市场进化"的问题，通过策略管理系统与周期性迭代机制，让每个选股策略可量化、可追踪、可进化。

**Office Hours 关键洞察**：
- 原始需求 vs 真实问题：用户说"需要策略管理功能"，真实问题是当前推荐列表仅依赖一套固定的技术分析引擎（MA + 布林带 + 量比 + 趋势），无法区分不同市场环境下的选股逻辑，也无法回答"这个策略到底准不准"
- 我们选择了：策略作为一等公民的管理对象（创建/编辑/启停），推荐列表按策略分组展示，策略通过周期性复盘自评迭代
- 信号强度：假设（0 真实用户，需验证）

**范围边界**：
- 本期做：策略 CRUD（Screen 3）、策略详情统计（Screen 5）、推荐列表按策略分组、策略迭代复盘机制（Check List + 打分）
- 本期不做：自然语言生成策略算法、大模型接入、策略云端同步、策略市场/分享、历史回测图表可视化

**前置条件**：v1.0 已完成的推荐列表、关注列表、标的详情页、技术分析引擎

---

## 1. 问题与 OKR

### 用户真实痛点

当 [散户投资者使用当前的推荐列表一段时间后] 时，
我想要 [知道当前这套选股逻辑的历史命中率，并能尝试不同的选股参数]，
这样我就可以 [根据市场环境调整策略，而不是盲目信任一套固定算法]。
[未验证假设]

**现有解决方案的具体缺陷**：
- 缺陷 1：当前 AnalysisEngine 是硬编码的一套指标（MA20/MA60 + 布林带 + 量比 + 趋势），权重固定（0.30/0.30/0.20/0.20），无法针对不同市场风格（短线打板 vs 中线波段）调整参数
- 缺陷 2：推荐列表按"短线波段"/"中线波段"分组，但分组依据仅依赖 score >= 7 && isBandLow，不是用户自主定义的策略逻辑
- 缺陷 3：无法回答"这个策略过去一个月命中率多少"，没有策略级别的统计和复盘数据

### Objective & Key Results

- **Objective**：让用户能管理多个选股策略，并看到每个策略的量化表现
  - KR1：用户可创建至少 3 个自定义策略并独立运行（基线：0，目标：3 个策略上线运行）
  - KR2：每个策略在运行 20 个交易日后展示命中率统计（基线：无统计，目标：100% 策略有统计面板）
  - KR3：策略迭代机制在策略运行满 30 个交易日后自动触发复盘 Check List（基线：0，目标：自动触发率 100%）

### 护栏指标（不能变差的东西）
- 推荐列表加载时间不能从当前水平（< 1.5s）增加超过 500ms
- 现有关注列表滑动操作帧率不低于 55fps（策略功能不影响现有体验）
- App 冷启动时间不超过 2.5s（增加了策略模块后）
- 数据库体积增长不超过 5MB/月（策略数据量需控制）

### 成功判断标准
3 个月后，如果用户至少创建了 2 个自定义策略，且策略详情页的周访问频次 >= 2 次/周，则视为策略管理功能被用户接受。若 90% 的策略在运行 20 个交易日后命中率低于 40%，则说明策略迭代机制需要重新设计。

---

## 2. 目标用户

25-45 岁散户投资者，已使用 v1.0 推荐列表，对固定策略产生质疑，希望有更多控制权。

**用户场景**：用户发现推荐准确率下降，想查看命中率、调整参数或切换策略。

| 阶段 | 痛点 | 解决方案 |
|------|------|---------|
| 策略认知 | 只有一套固定算法 | 策略管理页展示逻辑和参数 |
| 策略选择 | 无法切换调整 | 启用/停用，推荐按策略分组 |
| 策略评估 | 无统计数据 | 命中率、极限分值、平均差 |
| 策略进化 | 无复盘机制 | Check List + 打分 + 迭代建议 |

---

## 3. 功能需求（MoSCoW）

| ID | 功能 | 优先级 | RICE 分 | 工作量估计 | 说明 |
|----|------|--------|---------|-----------|------|
| F001 | 策略列表页（Screen 3 基础） | Must | 高 | 3-5天 | 策略 CRUD、启用/停用切换 |
| F002 | 策略创建/编辑表单 | Must | 高 | 3-5天 | 参数配置表单、策略名称/描述 |
| F003 | 推荐列表按策略分组展示 | Must | 高 | 3-5天 | 改造现有推荐列表，按策略维度分组 |
| F004 | 策略详情页（Screen 5） | Must | 高 | 3-5天 | 命中率、极限分值、平均差统计 |
| F005 | 策略执行引擎（多策略） | Must | 高 | 5-7天 | 每个策略独立运行分析，生成各自的推荐结果 |
| F006 | 策略命中记录持久化 | Must | 中 | 2-3天 | 每日记录策略推荐及后续实际涨跌，用于统计 |
| F007 | 策略周期性复盘打分 | Should | 中 | 3-5天 | 复盘 Check List 生成、策略健康度评分 |
| F008 | 策略迭代方向建议 | Should | 中 | 2-3天 | 基于统计数据给出参数调整建议 |
| F009 | 默认策略自动迁移 | Should | 中 | 1-2天 | 将现有硬编码策略迁移为可管理的默认策略 |
| F010 | 策略参数预设模板 | Could | 低 | 2-3天 | 预置"短线打板""中线波段""保守防御"等模板 |
| F011 | 策略回测历史图表 | Won't（本期）| -- | -- | 需要图表库和历史数据量支撑，v3 |
| F012 | 自然语言生成策略 | Won't（本期）| -- | -- | 需要大模型接入，v2+ |
| F013 | 策略云端同步 | Won't（本期）| -- | -- | 无服务器架构限制，v3+ |
| F014 | 策略市场/分享 | Won't（本期）| -- | -- | 无社交功能规划 |

---

## 4. 用户故事与验收标准

### Feature: F001 策略列表页

```gherkin
Feature: 策略列表页（Screen 3）

  Background:
    Given 用户已打开 App
    And 底部 Tab 栏新增"策略"Tab

  Scenario: 用户查看策略列表
    Given 用户至少有 1 个策略（含默认策略）
    When 用户进入"策略"Tab
    Then 展示策略列表，每个策略卡片显示：策略名称、策略描述摘要、当前状态（启用/停用）、命中率、健康度评分
    And 列表按启用状态排序（启用的在前），同状态下按命中率降序

  Scenario: 策略列表为空（首次使用）
    Given 用户首次使用，无任何自定义策略
    When 用户进入"策略"Tab
    Then 展示默认策略（自动创建的"默认波段策略"）
    And 底部展示"创建新策略"按钮

  Scenario: 用户点击"创建新策略"按钮后的交互中间态
    Given 用户在策略列表页
    When 用户点击右下角"+"或底部"创建新策略"按钮
    Then 跳转到策略创建表单页面

  Scenario: 策略列表加载中
    Given 用户进入"策略"Tab
    When 策略数据正在从 SQLite 加载
    Then 展示 Skeleton loading 占位动画（3 个策略卡片形状）

  Scenario: 策略列表加载失败（SQLite 异常）
    Given 用户进入"策略"Tab
    When SQLite 读取异常
    Then 展示错误提示"策略数据加载失败，请重启 App"
    And 展示"重试"按钮

  Scenario: 用户启用/停用策略的切换操作
    Given 策略列表中至少有 1 个停用的策略
    When 用户点击某策略卡片上的启用/停用开关
    Then 开关立即变为 disabled 状态（防止并发操作）
    When 数据库更新成功
    Then 开关动画切换到新状态
    And 若为"启用"，策略卡片移到列表上方；若为"停用"，策略卡片移到列表下方
    And Toast 提示"已启用 {策略名称}" 或 "已停用 {策略名称}"

  Scenario: 启用/停用策略数据库更新失败
    Given 用户点击了策略的启用/停用开关
    When SQLite 写入失败
    Then 开关恢复为原始状态
    And 展示 Toast "操作失败，请重试"
```

### Feature: F002 策略创建/编辑表单

```gherkin
Feature: 策略创建/编辑表单

  Background:
    Given 用户已进入策略创建或编辑页面

  Scenario: 用户成功创建策略
    Given 用户在策略创建表单页
    When 用户填写策略名称（必填，1-20 字符）
    And 用户填写策略描述（选填，最多 100 字符）
    And 用户配置策略参数：
      | 参数             | 类型     | 范围        | 默认值 |
      | MA 短期周期      | 数字     | 5-60        | 20     |
      | MA 长期周期      | 数字     | 20-120      | 60     |
      | 布林带周期       | 数字     | 10-40       | 20     |
      | 布林带标准差倍数  | 数字     | 1.0-3.0     | 2.0    |
      | MA 权重          | 数字     | 0.0-1.0     | 0.30   |
      | 布林带权重       | 数字     | 0.0-1.0     | 0.30   |
      | 量比权重         | 数字     | 0.0-1.0     | 0.20   |
      | 趋势权重         | 数字     | 0.0-1.0     | 0.20   |
      | 推荐阈值分数     | 数字     | 1-10        | 7      |
    And 四项权重之和为 1.0（误差 +/- 0.01）
    And 用户点击"保存"按钮
    Then "保存"按钮立即变为 disabled 并显示 loading 状态
    And 表单所有输入项变为 disabled
    When 策略数据写入 SQLite 成功
    Then 按钮恢复可点击
    And 返回策略列表页
    And Toast 提示"策略 {策略名称} 创建成功"
    And 新策略出现在列表中，状态为"启用"

  Scenario: 权重之和不等于 1.0 时提交被阻止
    Given 用户在策略创建表单页
    When 用户设置的权重之和不为 1.0（如 0.90）
    And 用户点击"保存"
    Then 表单不提交
    And 在权重区域下方展示红色错误提示"权重之和必须等于 1.0，当前合计 0.90"
    And "保存"按钮保持 disabled 状态

  Scenario: 策略名称为空时提交被阻止
    Given 用户在策略创建表单页
    When 用户未填写策略名称
    And 用户点击"保存"
    Then 表单不提交
    And 策略名称输入框下方展示红色错误提示"请输入策略名称"

  Scenario: MA 短期周期 >= MA 长期周期时警告
    Given 用户在策略创建表单页
    When 用户设置 MA 短期周期 >= MA 长期周期（如 60 >= 30）
    Then 展示黄色警告提示"MA 短期周期通常小于长期周期"
    And "保存"按钮仍可点击（警告不阻止提交）

  Scenario: 用户编辑已有策略
    Given 策略列表中至少有 1 个策略
    When 用户点击某策略卡片进入策略详情页
    And 用户点击右上角"编辑"按钮
    Then 跳转到策略编辑表单页，表单预填当前策略的所有参数
    When 用户修改参数并点击"保存"
    Then 策略参数更新到 SQLite
    And 返回策略详情页
    And Toast 提示"策略已更新"

  Scenario: 保存策略 SQLite 写入失败
    Given 用户在策略创建/编辑表单页
    When 用户点击"保存"按钮后 SQLite 写入失败
    Then 按钮恢复为可点击状态
    And 展示 Toast "保存失败，请重试"
    And 表单数据保留（用户无需重填）
```

### Feature: F003 推荐列表按策略分组展示

```gherkin
Feature: 推荐列表按策略分组展示

  Background:
    Given 用户已打开 App 并进入"推荐"Tab
    And 用户至少有 1 个启用的策略

  Scenario: 用户查看按策略分组的推荐列表
    Given 当日推荐数据已按各策略计算完成
    When 用户进入"推荐"Tab
    Then 推荐列表按策略分组展示
    And 每个分组标题显示：策略名称 + 策略今日推荐数量（如"默认波段策略 8只"）
    And 每组内部按策略评分降序排列
    And 各分组按策略命中率降序排列

  Scenario: 多个策略推荐了同一只股票
    Given 策略 A 和策略 B 都推荐了"中国平安"
    When 用户查看推荐列表
    Then 该股票在两个策略分组中分别出现
    And 每个分组中该股票的评分可能不同（因为各策略参数不同）

  Scenario: 仅有 1 个策略启用时推荐列表展示
    Given 用户仅启用了 1 个策略（如"默认波段策略"）
    When 用户查看推荐列表
    Then 推荐列表仅显示 1 个策略分组
    And 展示形式与 v1.0 类似（分组标题 + 列表项）

  Scenario: 所有策略均停用时推荐列表展示
    Given 用户停用了所有策略
    When 用户查看推荐列表
    Then 展示空状态页面
    And 提示文案"暂无启用的策略，请前往策略管理页启用至少一个策略"
    And 提供"前往策略管理"链接按钮

  Scenario: 推荐列表加载中（多策略计算）
    Given 用户进入"推荐"Tab
    When 多个策略正在并行计算推荐结果
    Then 展示 Skeleton loading（按策略分组数量的骨架屏）
    And 若部分策略计算完成，先展示已完成策略的分组，未完成的分组显示 Skeleton

  Scenario: 某策略计算异常时不影响其他策略
    Given 策略 A 计算正常，策略 B 计算异常（数据不足等）
    When 用户查看推荐列表
    Then 策略 A 的推荐列表正常展示
    And 策略 B 的分组区域显示"策略计算异常，暂无推荐"
    And 不影响其他策略的正常展示
```

### Feature: F004 策略详情页

```gherkin
Feature: 策略详情页（Screen 5）

  Background:
    Given 用户已从策略列表点击某策略卡片

  Scenario: 用户查看策略详情（有足够统计数据）
    Given 策略已运行 >= 20 个交易日
    When 用户进入策略详情页
    Then 页面顶部展示策略名称和描述
    And 展示统计卡片区域：
      | 指标         | 定义                                   | 展示格式            |
      | 命中率       | 推荐后 5 日内涨幅 > 0 的比例            | 百分比，如"62.5%"   |
      | 极限分值     | 命中推荐的最大涨幅和最大跌幅             | "+15.2% / -8.3%"    |
      | 平均差       | 所有推荐的平均涨幅                       | "+1.35%"            |
      | 总推荐次数   | 策略累计推荐了多少只（含重复）           | "48 次"             |
      | 健康度       | 综合评分（命中率*0.5 + 平均差正负*0.3 + 稳定性*0.2） | "7.2/10" |
    And 展示最近 20 条推荐记录列表（股票名、推荐日期、推荐时评分、5 日后实际涨跌幅）
    And 命中（涨跌幅 > 0）的记录标记绿色，未命中标记红色

  Scenario: 策略运行不足 20 个交易日
    Given 策略已运行 5 个交易日（不足 20 个）
    When 用户查看策略详情页
    Then 统计卡片区域展示已有数据（如"已运行 5 个交易日"）
    And 命中率等指标标注"数据不足，需 20 个交易日以上"
    And 最近推荐记录正常展示（已有 5 条）

  Scenario: 策略从未产生过推荐
    Given 策略刚创建，从未推荐过任何股票
    When 用户查看策略详情页
    Then 统计卡片区域所有指标显示 "--"
    And 推荐记录区域展示"该策略暂无推荐记录"

  Scenario: 策略详情页加载中
    Given 用户点击某策略卡片
    When 统计数据正在从 SQLite 计算
    Then 页面顶部策略名称正常展示（来自路由参数）
    And 统计卡片区域展示 Skeleton loading
    And 推荐记录区域展示 Skeleton

  Scenario: 策略详情页统计计算失败
    Given 用户点击某策略卡片
    When SQLite 查询异常
    Then 策略名称正常展示
    And 统计卡片区域展示"统计计算失败"
    And 提供"重新计算"按钮

  Scenario: 用户点击推荐记录中的股票
    Given 策略详情页有推荐记录列表
    When 用户点击某条推荐记录
    Then 跳转到该股票的详情页（复用 v1.0 的 StockDetailPage）

  Scenario: 用户在策略详情页点击"编辑"按钮后的交互中间态
    Given 用户在策略详情页
    When 用户点击右上角"编辑"按钮
    Then 跳转到策略编辑表单页（F002 的编辑场景）

  Scenario: 用户在策略详情页点击"删除"按钮
    Given 用户在策略详情页
    And 该策略不是默认策略
    When 用户点击"删除策略"按钮
    Then 弹出确认对话框"确认删除策略 {策略名称}？此操作不可恢复"
    When 用户点击"确认删除"
    Then 按钮立即 disabled
    When 删除成功
    Then 返回策略列表页
    And Toast 提示"已删除策略 {策略名称}"

  Scenario: 用户尝试删除默认策略
    Given 用户在默认策略的详情页
    When 用户查看页面
    Then "删除策略"按钮不显示或为 disabled 状态
    And 提示文案"默认策略不可删除，但可以编辑参数"
```

### Feature: F005 策略执行引擎

```gherkin
Feature: 策略执行引擎（多策略并行）

  Background:
    Given 系统有 N 个启用的策略
    And 每个策略有独立的参数配置

  Scenario: 多策略并行计算推荐
    Given 系统触发推荐计算（用户打开推荐 Tab 或定时任务触发）
    When 计算引擎开始工作
    Then 对每个启用的策略，使用该策略的参数独立计算评分
    And 每个策略产生各自的推荐列表
    And 计算过程使用 Isolate 避免阻塞 UI 线程

  Scenario: 策略参数影响评分结果
    Given 策略 A 的推荐阈值为 7，策略 B 的推荐阈值为 5
    And 策略 A 的 MA 权重为 0.40，策略 B 的 MA 权重为 0.10
    When 同一只股票在两个策略下计算评分
    Then 策略 A 可能评分为 6（不推荐），策略 B 可能评分为 5（推荐）
    And 该股票仅出现在策略 B 的推荐列表中

  Scenario: 策略计算超时降级
    Given 某策略的计算耗时超过 10 秒
    When 计算超时
    Then 该策略标记为"计算超时"
    And 推荐列表中该策略分组展示"计算超时，请稍后重试"
    And 不影响其他策略的推荐展示
```

### Feature: F006 策略命中记录持久化

```gherkin
Feature: 策略命中记录持久化

  Background:
    Given 每日推荐计算完成后

  Scenario: 系统自动记录策略推荐
    Given 策略 A 今日推荐了 3 只股票
    When 推荐计算完成并写入 DailyRecommendationCache
    Then 同时写入 StrategyHitRecord 表：
      | 字段            | 值                           |
      | strategy_id     | 策略 A 的 ID                 |
      | stock_code      | 推荐股票代码                  |
      | stock_name      | 推荐股票名称                  |
      | recommend_date  | 当日日期                      |
      | recommend_score | 推荐时的策略评分               |
      | actual_change_5d| NULL（5 个交易日后回填）       |
      | is_hit          | NULL（5 个交易日后回填）       |
    And 记录数 = 当日该策略推荐数量

  Scenario: 系统回填 5 日实际涨跌幅
    Given 策略 A 在 5 个交易日前推荐了"中国平安"，actual_change_5d 为 NULL
    When 今日收盘后（或用户打开 App 时触发回填检查）
    Then 系统查询"中国平安"5 个交易日前的收盘价和今日收盘价
    And 计算实际涨跌幅并更新 actual_change_5d
    And 若 actual_change_5d > 0，则 is_hit = true；否则 is_hit = false

  Scenario: 回填数据时行情数据不可用
    Given 系统尝试回填某条记录
    When 对应股票的行情数据在 SQLite 中不存在（停牌、退市等）
    Then actual_change_5d 保持 NULL
    And is_hit 保持 NULL
    And 下次触发时再次尝试回填

  Scenario: 命中记录数据量控制
    Given 策略 A 累计命中记录超过 500 条
    When 系统写入新的命中记录
    Then 自动清理该策略最旧的 100 条记录（保留最近 400 条）
    And 在清理前，已统计的命中率数据不受影响（统计基于现有记录计算）
```

### Feature: F007 策略周期性复盘打分

```gherkin
Feature: 策略周期性复盘打分

  Background:
    Given 策略已运行 >= 30 个交易日
    And 距离上次复盘 >= 30 个交易日（或首次复盘）

  Scenario: 系统自动生成复盘 Check List
    Given 策略 A 运行已满 30 个交易日
    When 用户进入策略详情页
    Then 页面顶部展示"复盘提醒"Banner："该策略已运行 30 个交易日，建议进行复盘"
    And Banner 包含"立即复盘"按钮
    When 用户点击"立即复盘"
    Then 展示复盘面板，包含以下 Check List 项：
      | # | 检查项                           | 数据来源                 | 自动判定           |
      | 1 | 近 30 日命中率是否 > 50%          | StrategyHitRecord        | 是/否              |
      | 2 | 近 30 日平均差是否为正             | StrategyHitRecord        | 是/否              |
      | 3 | 极限跌幅是否超过 -10%              | StrategyHitRecord        | 是/否              |
      | 4 | 命中率趋势是否下降（近 15 日 vs 前 15 日）| StrategyHitRecord  | 上升/持平/下降      |
      | 5 | 推荐频率是否合理（日均 0-10 只）    | StrategyHitRecord        | 正常/过多/过少      |
    And 每项旁边展示自动判定的数据依据

  Scenario: 用户确认复盘 Check List
    Given 复盘面板已展示 Check List
    When 用户查看各项检查结果
    Then 每项展示"通过"（绿色）或"需关注"（黄色）或"异常"（红色）
    And 底部展示综合健康度评分（0-10 分）
    And 提供文本输入框"本次复盘备注"（选填，最多 200 字）
    When 用户点击"确认复盘结果"
    Then 按钮立即 disabled 并显示 loading
    When 复盘记录写入 StrategyReview 表成功
    Then 按钮恢复
    And Toast 提示"复盘记录已保存"
    And Banner 消失

  Scenario: 复盘 Check List 中 3 项以上异常
    Given 复盘面板中 3 项以上标记为"异常"（红色）
    When 用户查看复盘面板
    Then 底部额外展示建议："该策略表现异常，建议考虑停用或调整参数"
    And 提供"停用策略"快捷按钮

  Scenario: 用户查看历史复盘记录
    Given 策略 A 有 >= 2 次复盘记录
    When 用户在策略详情页点击"历史复盘"
    Then 展示复盘记录时间线列表
    And 每条记录显示：复盘日期、健康度评分、备注摘要
    When 用户点击某条复盘记录
    Then 展示该次复盘的完整 Check List 结果
```

### Feature: F008 策略迭代方向建议

```gherkin
Feature: 策略迭代方向建议

  Background:
    Given 策略已完成至少 1 次复盘

  Scenario: 系统基于统计数据给出迭代建议
    Given 策略 A 的命中率为 35%（< 50%），平均差为 -0.8%
    When 用户在复盘面板查看迭代建议区域
    Then 展示建议列表：
      | 条件                         | 建议                                          |
      | 命中率 < 50%                | "推荐阈值偏低，建议将推荐阈值从 {当前值} 提高到 {当前值+1}" |
      | 平均差为负                   | "策略整体偏悲观，建议检查 MA 权重是否需要提高"              |
      | 极限跌幅 > 10%              | "策略选股波动过大，建议增加布林带权重以筛选更稳定的标的"       |
      | 命中率趋势下降               | "策略可能不适应近期市场环境，建议调整 MA 周期参数"            |
      | 推荐频率 > 10 只/日          | "推荐过多，建议提高推荐阈值"                                |
    And 每条建议标注"自动生成，仅供参考"

  Scenario: 用户采纳建议后跳转编辑
    Given 迭代建议区域有具体的参数调整建议
    When 用户点击某条建议旁的"采纳并编辑"按钮
    Then 跳转到策略编辑表单页
    And 对应参数已自动调整到建议值（用户可继续手动修改）

  Scenario: 策略表现良好时无迭代建议
    Given 策略 A 的命中率为 65%，平均差为 +2.1%，趋势稳定
    When 用户查看迭代建议区域
    Then 展示"当前策略表现良好，无需调整"
    And 不展示具体建议项
```

### Feature: F009 默认策略自动迁移

```gherkin
Feature: 默认策略自动迁移

  Background:
    Given 用户从 v1.0 升级到 v2.0
    And 本地已有推荐数据和关注列表

  Scenario: 首次打开 v2.0 自动创建默认策略
    Given 用户首次打开 v2.0 版本
    When App 检测到 Strategy 表为空
    Then 自动创建"默认波段策略"：
      | 参数          | 值                      |
      | 名称          | "默认波段策略"            |
      | 描述          | "MA20/60 + 布林带 + 量比 + 趋势评分" |
      | MA 短期       | 20                      |
      | MA 长期       | 60                      |
      | 布林带周期    | 20                      |
      | 布林带标准差  | 2.0                     |
      | MA 权重       | 0.30                    |
      | 布林带权重    | 0.30                    |
      | 量比权重      | 0.20                    |
      | 趋势权重      | 0.20                    |
      | 推荐阈值      | 7                       |
      | is_default    | true                    |
    And 该策略状态为"启用"
    And 现有推荐逻辑无缝切换到使用该策略的参数

  Scenario: 默认策略不可删除但可编辑
    Given "默认波段策略"的 is_default = true
    When 用户在策略详情页查看
    Then 无"删除"按钮
    And "编辑"按钮正常可用
    And 用户修改参数后策略正常运行
```

---

## 5. 数据模型设计

### 5.1 策略表（Strategies）

```dart
class Strategies extends Table {
  TextColumn get id => text()();                              // UUID
  TextColumn get name => text().withLength(min: 1, max: 20)();
  TextColumn get description => text().withLength(max: 100).nullable()();
  // --- 分析参数 ---
  IntColumn get maShortPeriod => integer().withDefault(const Constant(20))();
  IntColumn get maLongPeriod => integer().withDefault(const Constant(60))();
  IntColumn get bollPeriod => integer().withDefault(const Constant(20))();
  RealColumn get bollStdDev => real().withDefault(const Constant(2.0))();
  RealColumn get weightMA => real().withDefault(const Constant(0.30))();
  RealColumn get weightBoll => real().withDefault(const Constant(0.30))();
  RealColumn get weightVol => real().withDefault(const Constant(0.20))();
  RealColumn get weightTrend => real().withDefault(const Constant(0.20))();
  IntColumn get recommendThreshold => integer().withDefault(const Constant(7))();
  // --- 状态 ---
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  // --- 时间戳 ---
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastReviewAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 5.2 策略命中记录表（StrategyHitRecords）

```dart
class StrategyHitRecords extends Table {
  TextColumn get id => text()();                              // UUID
  TextColumn get strategyId => text()();                      // FK -> Strategies.id
  TextColumn get stockCode => text().withLength(min: 6, max: 10)();
  TextColumn get stockName => text().withLength(max: 50)();
  TextColumn get recommendDate => text().withLength(min: 10)(); // "2026-05-05"
  IntColumn get recommendScore => integer()();                 // 推荐时的策略评分 1-10
  RealColumn get recommendPrice => real()();                   // 推荐时收盘价
  RealColumn get actualChange5d => real().nullable()();         // 5 日后实际涨跌幅(%)
  BoolColumn get isHit => boolean().nullable()();               // actualChange5d > 0
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  // 索引: strategy_id + recommend_date（按策略查某日推荐）
  // 索引: strategy_id + is_hit NULL（查找未回填的记录）
}
```

### 5.3 策略复盘记录表（StrategyReviews）

```dart
class StrategyReviews extends Table {
  TextColumn get id => text()();                              // UUID
  TextColumn get strategyId => text()();                      // FK -> Strategies.id
  DateTimeColumn get reviewDate => dateTime()();
  RealColumn get healthScore => real()();                      // 健康度 0-10
  // --- Check List 结果 ---
  RealColumn get hitRate30d => real()();                       // 近 30 日命中率
  RealColumn get avgChange30d => real()();                     // 近 30 日平均差
  RealColumn get maxLoss30d => real().nullable()();            // 近 30 日极限跌幅
  TextColumn get hitRateTrend => text()();                     // "up" / "flat" / "down"
  IntColumn get avgDailyCount30d => integer()();               // 近 30 日日均推荐数
  // --- 各项检查结果 ---
  TextColumn get checklistResult => text()();                  // JSON 格式 Check List 详情
  TextColumn get note => text().withLength(max: 200).nullable()(); // 用户备注
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 5.4 数据模型关系

```
Strategies (1) -----> (N) StrategyHitRecords
    └-------> (N) StrategyReviews

Drift schema: v1 -> v2, 新增 3 张表, 自动插入默认策略
```

### 5.5 统计指标

- **命中率** = COUNT(is_hit=true) / COUNT(is_hit NOT NULL)
- **极限分值** = MAX/MIN(actual_change_5d)
- **平均差** = AVG(actual_change_5d)
- **健康度** = hit_rate_score*0.5 + avg_change_score*0.3 + stability_score*0.2

---

## 6. 非功能需求

- 策略列表加载 < 500ms，详情统计计算 < 1s
- 多策略推荐总计算时间 < N * 3s
- 策略 CRUD < 300ms，数据库月增长 < 5MB
- 数据存储本地 SQLite，无外部传输
- iOS 15+, Android 10+，数据库迁移 v1->v2 无损

---

## 7. 技术约束
待 Architect 评审后填写。关键技术决策点：
- 多策略并行计算是否使用 Isolate
- 策略命中记录 5 日回填的触发时机（App 打开时 vs workmanager 定时）
- 统计计算是否缓存（避免每次打开策略详情页重算）

---

## 8. Out of Scope（本期明确不做）

| 功能 | 不做原因 | 计划版本 |
|------|---------|---------|
| 自然语言生成策略 | 需要大模型 API 接入，初期不接入 LLM | v2+ |
| 策略回测历史图表 | 需要 fl_chart 或 similar 图表库，且历史数据量支撑 | v3 |
| 策略云端同步 | 无服务器架构限制，需引入后端 | v3+ |
| 策略市场/分享 | 无社交功能规划，用户群体小 | 无计划 |
| 策略导入/导出 | 可在 v2.1 考虑 JSON 文件导入导出 | v2.1 |
| 策略组合（多策略融合） | 复杂度高，需先验证单策略管理是否被用户接受 | v3+ |
| 自定义技术指标公式 | 需要表达式解析引擎，复杂度极高 | 无计划 |

---

## 9. 死亡条件

- 上线 4 周后用户平均创建策略数 < 1：功能过于复杂
- 策略迭代建议采纳率 < 10%：建议质量太低
- 多策略并行计算导致推荐列表加载 > 5s

## 10. Stakeholder 矩阵

| 角色 | 关心什么 | 需要做什么 |
|------|---------|-----------|
| 开发者 | 多策略计算架构、数据库迁移 | 评审 Isolate 方案、Drift schema 迁移 |
| 测试 | v1 兼容性、数据库迁移 | 编写迁移测试、策略计算测试 |

## 11. 导航结构变更

### v2.0 底部 Tab 栏（3 Tab）

```
App
├── Bottom Tab Bar
│   ├── 推荐 (RecommendTab)     -- /recommend       [改造: 按策略分组]
│   ├── 关注 (WatchlistTab)     -- /watchlist        [不变]
│   └── 策略 (StrategyTab)      -- /strategies       [新增]
│
├── 详情页 (StockDetailPage)    -- /stock/:code      [不变]
├── 策略详情页 (StrategyDetailPage) -- /strategy/:id  [新增]
└── 策略编辑页 (StrategyEditPage)   -- /strategy/:id/edit [新增, :id=new 时为创建]
```

### 新增路由

| 路由 | 页面 | 参数 |
|------|------|------|
| /strategies | 策略列表 Tab | -- |
| /strategy/:id | 策略详情页 | id: 策略 UUID |
| /strategy/new | 创建策略 | -- |
| /strategy/:id/edit | 编辑策略 | id: 策略 UUID |

---

## 12. 开放问题

1. 多策略并行计算是否使用 Isolate 还是 Compute？
2. 策略命中记录 5 日回填的触发时机
3. 统计计算结果是否缓存？缓存失效策略

## 13. 版本历史
| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-04-10 | 初稿 |
| 2.0 | 2026-05-05 | 新增策略管理、策略详情、按策略分组推荐、策略迭代复盘 |
