# 项目规划文档

## 1. 项目概述

| 项目 | 内容 |
|------|------|
| 项目名称 | MXS |
| 项目类型 | 回合制策略游戏（魔灵-like） |
| 引擎版本 | Godot 4.6 |
| 脚本语言 | GDScript 2.0 |
| 渲染器 | GL Compatibility |
| 仓库地址 | https://github.com/amazlothar/mxs.git |

## 2. 角色定义

### 用户（amazlothar）
- 项目所有者 / 主策划
- 负责游戏设计决策、需求定义、验收

### 助手（opencode）
- 高级游戏架构师
- 精通 Godot 4.6、GDScript 2.0
- 负责技术架构设计、代码实现、问题排查
- 主动提出架构建议和最佳实践

## 3. 核心系统

### 3.1 ATB（Active Time Battle）行动条系统
- 基于速度属性的行动条机制
- 角色速度决定行动顺序和频率
- 需要支持行动条的暂停、加速等状态

### 3.2 Buff / Debuff 系统
- 复杂的叠加逻辑（刷新、叠加、互斥等）
- 支持多种效果类型
- 需要支持 Buff 之间的交互和覆盖规则

### 3.3 装备系统
- 6 槽位：头部、上装、下装、鞋、饰品、武器
- 数据驱动设计，使用 Godot Resource 类进行数据定义
- 套装效果（2件/4件两档），影响角色属性和技能效果

## 4. 技术架构原则

| 原则 | 说明 |
|------|------|
| 数据驱动 | 优先使用 `Resource` 类处理游戏数据（角色、技能、装备、Buff 等） |
| 信号解耦 | 使用 `Signals` 实现系统间通信，降低耦合度 |
| 组件化 | 功能模块化，便于复用和测试 |
| 单一职责 | 每个类/脚本只负责一个明确的功能 |

## 5. 目录结构规划

```
mxs/
├── project.godot
├── docs/                    # 文档
│   ├── communication_log.md # 沟通记录
│   ├── project_plan.md      # 项目规划
│   └── superpowers/specs/   # 设计文档
├── scenes/                  # 场景文件 (.tscn)
│   └── battle/              # 战斗场景
├── scripts/                 # 脚本文件 (.gd)
│   ├── core/                # 核心系统（BattleManager、ATB、Skill、Buff、Damage）
│   ├── data/                # 数据类（Resource 子类）
│   ├── ai/                  # AI 控制器
│   ├── components/          # 可复用组件
│   └── ui/                  # UI 脚本
├── resources/               # Resource 资源文件 (.tres)
│   ├── characters/          # 角色数据
│   ├── skills/              # 技能数据
│   ├── equipments/          # 装备数据
│   ├── equip_sets/          # 套装数据
│   └── buffs/               # Buff 数据
├── assets/                  # 美术/音频资源
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── tests/                   # 测试
```

## 6. 开发里程碑

1. **M1 - 基础框架**：项目结构、枚举定义、Resource 数据类（UnitData、SkillData、SkillEffect、BuffData、EquipData、EquipSetData）
2. **M2 - ATB 系统**：行动条充能逻辑、就绪判定、暂停/恢复、速度队列
3. **M3 - Buff/Debuff 系统**：效果框架、叠加策略、互斥组、驱散规则、属性修正
4. **M4 - 装备系统**：6 槽位装备、套装效果、属性加成计算
5. **M5 - 技能与伤害系统**：技能释放流程、伤害公式、元素克制、暴击命中、多段攻击
6. **M6 - 战斗流程串联**：BattleManager 完整循环、AI 控制器、死亡/复活/控制处理
7. **M7 - UI 与交互**：战斗界面、单位卡片（充能条+血条+Buff）、技能栏、ATB 汇总条、伤害数字

## 7. 沟通规范

- 所有对话记录到 `docs/communication_log.md`
- 重要决策和变更同步更新本文档
- 代码提交信息使用中文描述
