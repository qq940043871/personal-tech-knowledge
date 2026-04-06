# 人工智能学习详细教程

> 本教程涵盖机器学习入门到大型语言模型实战的全链路学习路径
> 适合零基础入门到进阶的系统学习

---

# 第一章：机器学习入门

## 1.1 基础概念

### 人工智能、机器学习与深度学习的关系

**人工智能（AI）** 是最广泛的概念，指的是让机器具有人类智能的技术。它包括机器学习、深度学习、自然语言处理、计算机视觉、机器人学等多个分支。

**机器学习（ML）** 是人工智能的一个子领域，它让计算机通过数据学习自动提升性能，而无需显式编程。机器学习又分为传统机器学习和深度学习。

**深度学习（DL）** 是机器学习的一个分支，使用多层神经网络（深度神经网络）来学习数据的层次化表示。深度学习是机器学习发展最快、最热门的领域。

三者的关系可以理解为：
```
人工智能（AI）
    └── 机器学习（ML）
            └── 深度学习（DL）
```

### 机器学习的三大类型

#### 1. 监督学习（Supervised Learning）

监督学习是最常见的机器学习类型。在训练过程中，每个样本都有一个对应的"标签"（正确答案）。模型学习从输入到输出的映射关系。

**典型应用场景：**
- 分类问题：判断邮件是否为垃圾邮件（标签：垃圾邮件/正常邮件）
- 回归问题：预测房价（标签：实际房价数值）

**常见算法：** 线性回归、逻辑回归、决策树、随机森林、SVM、神经网络

#### 2. 无监督学习（Unsupervised Learning）

无监督学习没有标签，模型需要自行发现数据的内在结构和规律。

**典型应用场景：**
- 聚类：将客户分群（不知道具体类别）
- 降维：压缩数据维度同时保留重要信息
- 异常检测：发现异常数据点

**常见算法：** K-means、层次聚类、DBSCAN、PCA、t-SNE、自编码器

#### 3. 强化学习（Reinforcement Learning）

强化学习通过智能体与环境的交互学习最优策略。智能体根据当前状态采取行动，获得奖励或惩罚，逐步学习最优决策。

**典型应用场景：**
- 游戏AI：围棋、星际争霸
- 机器人控制
- 自动驾驶
- 推荐系统

**核心概念：** 智能体（Agent）、环境（Environment）、状态（State）、动作（Action）、奖励（Reward）、策略（Policy）

### 训练集、验证集与测试集

机器学习模型开发过程中，通常将数据划分为三个部分：

| 数据集 | 作用 | 通常占比 |
|--------|------|---------|
| **训练集（Training Set）** | 用于模型学习参数 | 60-80% |
| **验证集（Validation Set）** | 用于调参和选择模型 | 10-20% |
| **测试集（Test Set）** | 用于最终评估模型性能 | 10-20% |

**重要原则：** 测试集必须与训练集完全独立，在模型开发完成前绝对不能使用测试集来调整模型，否则会导致"数据泄露"。

### 过拟合与欠拟合

#### 过拟合（Overfitting）

过拟合指模型在训练数据上表现很好，但在测试数据或新数据上表现较差。原因是模型过于复杂，记住了训练数据的噪声和细节，而不是学习到通用的规律。

**过拟合的表现：**
- 训练误差很小，但测试误差很大
- 模型在训练集上的准确率接近100%，但测试集上只有70-80%

**解决过拟合的方法：**
- 增加训练数据量
- 简化模型（减少参数）
- 正则化（L1、L2、Dropout）
- 交叉验证
- 早停法（Early Stopping）

#### 欠拟合（Underfitting）

欠拟合指模型过于简单，无法很好地学习训练数据的模式，导致在训练集和测试集上表现都不佳。

**解决欠拟合的方法：**
- 增加模型复杂度
- 增加特征（特征工程）
- 减少正则化强度
- 训练更长时间

### 偏差-方差权衡（Bias-Variance Tradeoff）

偏差（Bias）：模型预测值与真实值的差异，反映模型的拟合能力
方差（Variance）：模型预测值的波动范围，反映模型的稳定程度

| | 高偏差（欠拟合） | 低偏差 | 高方差（过拟合） | 低方差 |
|---|---|---|---|---|
| 训练误差 | 高 | 低 | 低 | 低 |
| 测试误差 | 高 | 低 | 高 | 低 |
| 模型复杂度 | 太低 | 适中 | 太高 | 适中 |

**目标：** 找到偏差和方差的最佳平衡点，使总误差最小。

---

## 1.2 数学基础

### 线性代数

线性代数是机器学习的数学基础之一，主要研究向量、向量空间和线性变换。

#### 标量、向量、矩阵、张量

- **标量（Scalar）**：单个数值，如 3、-1.5
- **向量（Vector）**：一维数组，如 [1, 2, 3]
- **矩阵（Matrix）**：二维数组，如 [[1,2],[3,4]]
- **张量（Tensor）**：多维数组，神经网络中的数据通常是多维张量

#### 矩阵运算

```python
import numpy as np

# 向量
a = np.array([1, 2, 3])
b = np.array([4, 5, 6])

# 加减
c = a + b  # [5, 7, 9]
d = a - b  # [-3, -3, -3]

# 点积（Dot Product）
dot = np.dot(a, b)  # 1*4 + 2*5 + 3*6 = 32

# 矩阵乘法
A = np.array([[1, 2], [3, 4]])
B = np.array([[5, 6], [7, 8]])
C = np.matmul(A, B)
```

#### 特征值与特征向量

对于 n×n 矩阵 A，如果存在非零向量 v 和标量 λ，使得：
```
A·v = λ·v
```
则 λ 是 A 的特征值，v 是对应的特征向量。

特征值分解在主成分分析（PCA）中用于降维，在PageRank算法中用于排序。

### 概率论

概率论是机器学习中最重要的数学基础之一。

#### 概率分布

- **均匀分布**：每个结果概率相等
- **正态分布（高斯分布）**：最常见的连续概率分布
- **伯努利分布**：只有两个结果的分布（如抛硬币）
- **多项分布**：多个类别结果的分布

#### 贝叶斯定理

贝叶斯定理是概率论中最重要的定理之一：
```
P(A|B) = P(B|A) · P(A) / P(B)
```

其中：
- P(A|B)：后验概率，已知B发生的情况下A的概率
- P(B|A)：似然度，已知A发生时B的概率
- P(A)：先验概率，A的先验概率
- P(B)：边缘概率

**应用场景：** 朴素贝叶斯分类器、垃圾邮件过滤

#### 期望与方差

- **期望（Expected Value）**：随机变量的平均值
- **方差（Variance）**：随机变量与期望的偏离程度
- **标准差（Standard Deviation）**：方差的平方根

### 微积分

微积分，特别是导数和偏导数，是优化算法的基础。

#### 导数

导数表示函数在某一点的变化率：
```
f'(x) = lim(h→0) [f(x+h) - f(x)] / h
```

#### 偏导数

多变量函数的偏导数：
```
∂f/∂x 表示函数f对x的导数，y保持不变
```

#### 链式法则

复合函数的导数：
```
(f(g(x)))' = f'(g(x)) · g'(x)
```

链式法则是反向传播算法的数学基础。

### 信息论

信息论研究信息的量化、存储和传输。

#### 熵（Entropy）

熵表示随机变量的不确定性：
```
H(X) = -Σ P(x) · log₂ P(x)
```

熵越大，不确定性越高。

#### 交叉熵（Cross Entropy）

交叉熵用于衡量两个概率分布的差异：
```
H(P, Q) = -Σ P(x) · log Q(x)
```

交叉熵是分类问题中损失函数的理论基础。

#### KL散度（KL Divergence）

KL散度衡量两个概率分布的差异：
```
KL(P || Q) = Σ P(x) · log(P(x) / Q(x))
```

---

## 1.3 经典算法

### 线性回归（Linear Regression）

线性回归是最简单也是最重要的回归算法。

**核心思想：** 用一条直线（或超平面）拟合数据：
```
y = wx + b
```

**损失函数（均方误差）：**
```
MSE = (1/n) · Σ(yᵢ - ŷᵢ)²
```

**代码实现：**
```python
from sklearn.linear_model import LinearRegression
import numpy as np

# 准备数据
X = np.array([[1], [2], [3], [4], [5]])
y = np.array([2, 4, 6, 8, 10])

# 训练模型
model = LinearRegression()
model.fit(X, y)

# 预测
y_pred = model.predict([[6]])
print(y_pred)  # [12.]
```

### 逻辑回归（Logistic Regression）

逻辑回归是分类算法，尽管名字有"回归"，但主要用于分类。

**核心思想：** 使用Sigmoid函数将线性输出转换为概率：
```
P(y=1|x) = 1 / (1 + e^-(wx+b))
```

**损失函数（对数损失）：**
```
L = -[y·log(ŷ) + (1-y)·log(1-ŷ)]
```

**代码实现：**
```python
from sklearn.linear_model import LogisticRegression
from sklearn.datasets import make_classification

# 生成数据
X, y = make_classification(n_samples=100, n_features=2, n_redundant=0)

# 训练模型
model = LogisticRegression()
model.fit(X, y)

# 预测
y_pred = model.predict(X)
```

### 决策树（Decision Tree）

决策树通过一系列规则对数据进行分类或回归。

**核心概念：**
- **节点**：数据划分的判断点
- **叶节点**：最终分类或回归结果
- **信息增益**：划分后不确定性的减少
- **基尼不纯度**：衡量数据集的纯度

**代码实现：**
```python
from sklearn.tree import DecisionTreeClassifier

model = DecisionTreeClassifier(max_depth=3)
model.fit(X, y)
y_pred = model.predict(X)
```

### 随机森林（Random Forest）

随机森林是由多棵决策树组成的集成算法，通过投票或平均来获得最终结果。

**核心思想：**
- **Bagging**：Bootstrap Aggregating，自助采样
- **特征随机选择**：每次分裂只考虑部分特征

**优点：**
- 抗过拟合能力强
- 可以处理高维数据
- 可以评估特征重要性

**代码实现：**
```python
from sklearn.ensemble import RandomForestClassifier

model = RandomForestClassifier(n_estimators=100, max_depth=10)
model.fit(X, y)
```

### 支持向量机（Support Vector Machine, SVM）

SVM通过找到最优分隔超平面来分类数据。

**核心概念：**
- **支持向量**：距离超平面最近的数据点
- **间隔（Margin）**：支持向量到超平面的距离
- **核函数（Kernel）**：将数据映射到高维空间

**核函数类型：**
- 线性核
- 多项式核
- RBF（径向基函数）核

**代码实现：**
```python
from sklearn.svm import SVC

# 线性SVM
model = SVC(kernel='linear')
model.fit(X, y)

# 使用RBF核
model = SVC(kernel='rbf', C=1.0, gamma='scale')
```

### K近邻算法（K-Nearest Neighbors, KNN）

KNN是最简单的分类算法之一，通过找最近的K个邻居来预测类别。

**核心思想：** "物以类聚"，相似的样本具有相似的标签

**算法步骤：**
1. 计算待分类样本与所有训练样本的距离
2. 选取最近的K个邻居
3. 根据邻居的类别投票决定待分类样本的类别

**代码实现：**
```python
from sklearn.neighbors import KNeighborsClassifier

model = KNeighborsClassifier(n_neighbors=5)
model.fit(X, y)
y_pred = model.predict(X)
```

### K-means聚类

K-means是最常用的聚类算法之一。

**核心思想：** 将数据划分为K个簇，使簇内数据点尽可能相似

**算法步骤：**
1. 随机选择K个中心点
2. 将每个数据点分配给最近的中心点
3. 重新计算每个簇的中心点
4. 重复2-3步直到收敛

**代码实现：**
```python
from sklearn.cluster import KMeans

model = KMeans(n_clusters=3)
labels = model.fit_predict(X)
centers = model.cluster_centers_
```

---

## 1.4 评估指标

### 分类问题评估指标

#### 准确率（Accuracy）

正确分类的样本占总样本的比例：
```
Accuracy = (TP + TN) / (TP + TN + FP + FN)
```

#### 精确率（Precision）

预测为正类的样本中，真正为正类的比例：
```
Precision = TP / (TP + FP)
```

#### 召回率（Recall）

实际为正类的样本中，被正确预测的比例：
```
Recall = TP / (TP + FN)
```

#### F1分数

精确率和召回率的调和平均数：
```
F1 = 2 × (Precision × Recall) / (Precision + Recall)
```

#### 混淆矩阵

| | 预测为正 | 预测为负 |
|---|---|---|
| **实际为正** | TP（真正例） | FN（假负例） |
| **实际为负** | FP（假正例） | TN（真负例） |

#### ROC曲线与AUC

- **ROC曲线**：不同阈值下TPR（True Positive Rate）和FPR（False Positive Rate）的曲线
- **AUC（Area Under Curve）**：ROC曲线下的面积，取值0-1，越大越好

```python
from sklearn.metrics import roc_curve, roc_auc_score, confusion_matrix

# 混淆矩阵
cm = confusion_matrix(y_true, y_pred)

# ROC曲线
fpr, tpr, thresholds = roc_curve(y_true, y_prob)

# AUC
auc = roc_auc_score(y_true, y_prob)
```

### 回归问题评估指标

#### 均方误差（MSE, Mean Squared Error）
```
MSE = (1/n) × Σ(yᵢ - ŷᵢ)²
```

#### 均方根误差（RMSE, Root Mean Squared Error）
```
RMSE = √MSE
```

#### 平均绝对误差（MAE, Mean Absolute Error）
```
MAE = (1/n) × Σ|yᵢ - ŷᵢ|
```

#### 决定系数（R²）
```
R² = 1 - Σ(yᵢ - ŷᵢ)² / Σ(yᵢ - ȳ)²
```

R²越接近1，表示模型拟合效果越好。

```python
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

mse = mean_squared_error(y_true, y_pred)
rmse = np.sqrt(mse)
mae = mean_absolute_error(y_true, y_pred)
r2 = r2_score(y_true, y_pred)
```

---

# 第二章：深度学习基础

## 2.1 神经网络基础

### 感知机（Perceptron）

感知机是最简单的神经网络模型，由Frank Rosenblatt于1957年提出。

**结构：**
- 输入层：接收特征
- 权重：每个输入的连接权重
- 偏置：额外的可调参数
- 激活函数：将结果转换为输出

**前向传播：**
```
z = Σ(wᵢ × xᵢ) + b
y = f(z)
```

**感知机的局限性：** 只能处理线性可分问题，无法解决XOR问题。

### 多层感知机（MLP）

MLP由多层神经元组成，包含输入层、一个或多个隐藏层、输出层。

**结构：**
```
输入层 → 隐藏层1 → 隐藏层2 → ... → 输出层
```

**全连接（Fully Connected）：** 每层的每个神经元都与下一层的所有神经元相连

```python
import torch
import torch.nn as nn

class MLP(nn.Module):
    def __init__(self, input_size, hidden_size, output_size):
        super(MLP, self).__init__()
        self.layer1 = nn.Linear(input_size, hidden_size)
        self.relu = nn.ReLU()
        self.layer2 = nn.Linear(hidden_size, output_size)
    
    def forward(self, x):
        x = self.layer1(x)
        x = self.relu(x)
        x = self.layer2(x)
        return x
```

### 激活函数

激活函数为神经网络引入非线性，使其能够学习复杂模式。

#### Sigmoid函数
```
σ(x) = 1 / (1 + e^(-x))
```
- 输出范围：(0, 1)
- 缺点：梯度消失、输出不以0为中心

#### Tanh函数
```
tanh(x) = (e^x - e^(-x)) / (e^x + e^(-x))
```
- 输出范围：(-1, 1)
- 缺点：梯度消失

#### ReLU函数
```
ReLU(x) = max(0, x)
```
- 优点：计算快、缓解梯度消失
- 缺点：Dying ReLU问题（负数区域梯度为0）

#### Leaky ReLU
```
LeakyReLU(x) = x if x > 0 else αx (α usually 0.01)
```

#### Softmax函数
用于多分类问题的输出层：
```
Softmax(xᵢ) = e^(xᵢ) / Σ e^(xⱼ)
```

### 前向传播与反向传播

#### 前向传播（Forward Propagation）
数据从输入层流向输出层，逐层计算。

#### 反向传播（Backpropagation）
根据损失函数计算梯度，从后向前传播以更新参数。

**核心算法：链式法则**
```
∂L/∂w = ∂L/∂y × ∂y/∂z × ∂z/∂w
```

### 梯度下降与优化器

#### 梯度下降（Gradient Descent）
```
w = w - α × ∂L/∂w
```
其中α是学习率。

#### 批量梯度下降（Batch GD）
每次使用全部数据计算梯度，梯度估计准确但计算量大。

#### 随机梯度下降（SGD）
每次使用单个样本计算梯度，速度快但噪声大。

#### Mini-batch GD
每次使用一小批样本，平衡速度和准确性。

#### 动量（Momentum）
添加历史梯度信息，加速收敛：
```
v = βv + (1-β)×grad
w = w - α×v
```

#### Adam（Adaptive Moment Estimation）
结合Momentum和RMSProp，自适应学习率：
```python
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
```

---

## 2.2 深度神经网络训练技巧

### 初始化策略

#### Xavier初始化
适用于Sigmoid和Tanh：
```
W ~ N(0, √(1/n))  或  U(-√(6/n), √(6/n))
```

#### He初始化
适用于ReLU：
```
W ~ N(0, √(2/n))
```

```python
# PyTorch中
nn.Linear(in_features, out_features, bias=False)
# 默认使用Kaiming初始化（He初始化）
```

### 归一化技术

#### Batch Normalization
对每个batch进行标准化：
```
μ = mean(batch)
σ = std(batch)
x_norm = (x - μ) / σ
y = γ × x_norm + β
```

优点：加速训练、稳定梯度、支持更高学习率

```python
nn.BatchNorm2d(num_features)
```

#### Layer Normalization
对每个样本进行标准化，常用于RNN和Transformer。

#### Instance Normalization
用于风格迁移等任务。

### 正则化

#### Dropout
训练时随机"丢弃"部分神经元：
```python
nn.Dropout(p=0.5)  # 50%概率丢弃
```

#### 权重衰减（Weight Decay）
在损失函数中添加L2正则化项：
```python
optimizer = torch.optim.Adam(model.parameters(), weight_decay=0.01)
```

### 学习率调度

#### Step LR
固定步长降低学习率：
```python
scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=10, gamma=0.1)
```

#### Cosine Annealing
余弦退火：
```python
scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=50)
```

#### ReduceLROnPlateau
验证集指标不再下降时降低学习率：
```python
scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, 'min', patience=5)
```

### 梯度裁剪

防止梯度爆炸：
```python
torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
```

---

## 2.3 序列模型

### RNN（循环神经网络）

RNN通过隐藏状态传递历史信息，适合处理序列数据。

**结构：**
```
h_t = tanh(W·x_t + U·h_{t-1})
y_t = V·h_t
```

**问题：梯度消失/爆炸**

### LSTM（长短期记忆网络）

LSTM通过门控机制解决长序列依赖问题。

**核心组件：**
- **遗忘门**：决定丢弃什么信息
- **输入门**：决定存储什么信息
- **输出门**：决定输出什么信息

```python
# PyTorch中的LSTM
lstm = nn.LSTM(input_size=256, hidden_size=512, num_layers=2, batch_first=True)
output, (hidden, cell) = lstm(input_tensor)
```

### GRU（门控循环单元）

GRU是LSTM的简化版本，参数更少，但效果相近。

```python
gru = nn.GRU(input_size=256, hidden_size=512, num_layers=2, batch_first=True)
```

### 双向RNN与深层RNN

- **双向RNN**：同时考虑序列的前后信息
- **深层RNN**：多层堆叠，增加模型容量

```python
# 双向LSTM
lstm = nn.LSTM(input_size=256, hidden_size=512, num_layers=2, 
               batch_first=True, bidirectional=True)
```

---

## 2.4 卷积神经网络（CNN）

### 卷积层

**卷积操作：**
- 卷积核（Kernel/Filter）在输入上滑动
- 逐元素相乘并求和
- 产生特征图（Feature Map）

**关键参数：**
- 卷积核大小（如3×3、5×5）
- 步长（Stride）
- 填充（Padding）

### 池化层

- **Max Pooling**：取最大值
- **Average Pooling**：取平均值

作用：减少特征维度、提取主要特征、增加平移不变性

### 全连接层与Softmax

- 全连接层：将特征映射到类别空间
- Softmax：将输出转换为概率分布

### 经典CNN架构

#### LeNet-5（1998）
- 第一个卷积神经网络
- 用于手写数字识别（MNIST）

#### AlexNet（2012）
- ImageNet竞赛冠军
- ReLU激活函数、Dropout

#### VGG（2014）
- 使用更小的3×3卷积核
- 16-19层网络

#### GoogLeNet（2014）
- Inception模块
- 减少参数数量

#### ResNet（2015）
- 残差连接（Skip Connection）
- 解决深层网络梯度消失问题
- 可训练超过1000层

```python
# 使用预训练ResNet
import torchvision.models as models

resnet = models.resnet50(pretrained=True)
# 修改最后一层用于自己的分类任务
resnet.fc = nn.Linear(resnet.fc.in_features, num_classes)
```

### 迁移学习

使用在大规模数据上预训练的模型，微调用于自己的任务。

```python
# 冻结前面层，只训练最后几层
for param in model.parameters():
    param.requires_grad = False

# 解冻最后几层
for param in model.layer4.parameters():
    param.requires_grad = True
```

---

## 2.5 注意力机制

### 注意力机制原理

注意力机制让模型关注输入中最相关的部分。

**核心概念：**
- **Query（查询）**：当前要处理的内容
- **Key（键）**：用于匹配的标识
- **Value（值）**：实际的信息内容

**计算过程：**
```
attention(Q, K, V) = softmax(QK^T / √d_k) × V
```

### 自注意力（Self-Attention）

自注意力是每个位置关注序列中所有位置：

```python
# 简化的自注意力
import torch.nn.functional as F

def self_attention(Q, K, V, mask=None):
    d_k = Q.size(-1)
    scores = torch.matmul(Q, K.transpose(-2, -1)) / math.sqrt(d_k)
    
    if mask is not None:
        scores = scores.masked_fill(mask == 0, -1e9)
    
    attn_weights = F.softmax(scores, dim=-1)
    return torch.matmul(attn_weights, V)
```

### 多头注意力（Multi-Head Attention）

并行运行多个注意力机制：

```python
class MultiHeadAttention(nn.Module):
    def __init__(self, d_model, num_heads):
        super().__init__()
        self.d_model = d_model
        self.num_heads = num_heads
        self.d_k = d_model // num_heads
        
        self.W_q = nn.Linear(d_model, d_model)
        self.W_k = nn.Linear(d_model, d_model)
        self.W_v = nn.Linear(d_model, d_model)
        self.W_o = nn.Linear(d_model, d_model)
    
    def forward(self, Q, K, V, mask=None):
        batch_size = Q.size(0)
        
        # 线性变换并分割为多个头
        Q = self.W_q(Q).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        K = self.W_k(K).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        V = self.W_v(V).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        
        # 计算注意力
        scores = torch.matmul(Q, K.transpose(-2, -1)) / math.sqrt(self.d_k)
        if mask is not None:
            scores = scores.masked_fill(mask == 0, -1e9)
        attn = F.softmax(scores, dim=-1)
        
        # 合并多个头
        out = torch.matmul(attn, V)
        out = out.transpose(1, 2).contiguous().view(batch_size, -1, self.d_model)
        return self.W_o(out)
```

### 位置编码

Transformer需要位置信息：

```python
class PositionalEncoding(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len).unsqueeze(1).float()
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-math.log(10000.0) / d_model))
        
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0)
        self.register_buffer('pe', pe)
    
    def forward(self, x):
        return x + self.pe[:, :x.size(1)]
```

---

## 2.6 Transformer架构

### Encoder-Decoder结构

**Encoder：**
- 堆叠多个相同的层
- 每层包含：多头自注意力 + 前馈网络
- 残差连接和层归一化

**Decoder：**
- 额外的Masked多头自注意力
- 编码器-解码器注意力

```python
class Transformer(nn.Module):
    def __init__(self, src_vocab_size, tgt_vocab_size, d_model=512, nhead=8, num_layers=6):
        super().__init__()
        self.encoder = Encoder(src_vocab_size, d_model, nhead, num_layers)
        self.decoder = Decoder(tgt_vocab_size, d_model, nhead, num_layers)
        self.output = nn.Linear(d_model, tgt_vocab_size)
    
    def forward(self, src, tgt, src_mask=None, tgt_mask=None):
        enc_out = self.encoder(src, src_mask)
        dec_out = self.decoder(tgt, enc_out, src_mask, tgt_mask)
        return self.output(dec_out)
```

### BERT：双向编码器表示

- **预训练任务**：MLM（掩码语言模型）+ NSP（下一句预测）
- **应用**：文本分类、问答、命名实体识别

```python
from transformers import BertModel, BertTokenizer

model = BertModel.from_pretrained('bert-base-chinese')
tokenizer = BertTokenizer.from_pretrained('bert-base-chinese')
```

### GPT：自回归生成模型

- **预训练任务**：Next Token Prediction
- **应用**：文本生成、对话

```python
from transformers import GPT2LMHeadModel, GPT2Tokenizer

model = GPT2LMHeadModel.from_pretrained('gpt2')
tokenizer = GPT2Tokenizer.from_pretrained('gpt2')
```

### T5：Text-to-Text统一框架

将所有NLP任务统一为文本到文本的格式。

---

# 第三章：常用框架和常用库

```python
# XGBoost分类器
model = xgb.XGBClassifier(
    n_estimators=100,
    max_depth=6,
    learning_rate=0.1,
    objective='binary:logistic'
)
model.fit(X_train, y_train)

# LightGBM分类器
model = lgb.LGBMClassifier(
    n_estimators=100,
    max_depth=6,
    learning_rate=0.1,
    verbose=-1
)
model.fit(X_train, y_train)
```

### Optuna（超参数优化）

```python
import optuna
from optuna.samplers import TPESampler

def objective(trial):
    n_estimators = trial.suggest_int('n_estimators', 50, 300)
    max_depth = trial.suggest_int('max_depth', 3, 10)
    learning_rate = trial.suggest_float('learning_rate', 0.01, 0.3)
    
    model = xgb.XGBClassifier(
        n_estimators=n_estimators,
        max_depth=max_depth,
        learning_rate=learning_rate
    )
    score = cross_val_score(model, X, y, cv=3).mean()
    return score

study = optuna.create_study(direction='maximize', sampler=TPESampler())
study.optimize(objective, n_trials=100)

print(f"Best params: {study.best_params}")
print(f"Best score: {study.best_value}")
```

### MLflow（实验管理）

```python
import mlflow
import mlflow.sklearn

mlflow.set_experiment("my_experiment")

with mlflow.start_run():
    # 记录参数
    mlflow.log_param("n_estimators", 100)
    mlflow.log_param("max_depth", 6)
    
    # 训练模型
    model.fit(X_train, y_train)
    
    # 记录指标
    mlflow.log_metric("accuracy", accuracy_score(y_test, y_pred))
    
    # 保存模型
    mlflow.sklearn.log_model(model, "model")
```

### Transformers（Hugging Face）

```python
from transformers import AutoTokenizer, AutoModel

# 加载预训练模型
tokenizer = AutoTokenizer.from_pretrained("bert-base-chinese")
model = AutoModel.from_pretrained("bert-base-chinese")

# 编码文本
inputs = tokenizer("你好世界", return_tensors="pt")
outputs = model(**inputs)
```

---

# 第四章：机器学习实战

## 4.1 项目流程规范

### 1. 问题定义与数据理解

**明确问题类型：**
- 分类（二分类、多分类）
- 回归
- 聚类
- 排序
- 生成

**业务理解：**
- 业务目标是什么？
- 数据从哪里来？
- 预测结果如何被使用？

### 2. 数据收集与清洗

```python
# 加载数据
import pandas as pd
import numpy as np

df = pd.read_csv('data.csv')

# 查看数据
print(df.head())
print(df.info())
print(df.describe())

# 缺失值处理
print(df.isnull().sum())
df = df.dropna()  # 删除缺失值
# df = df.fillna(df.mean())  # 用均值填充
# df = df.fillna(method='ffill')  # 前向填充

# 异常值处理
Q1 = df['column'].quantile(0.25)
Q3 = df['column'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR
df = df[(df['column'] >= lower_bound) & (df['column'] <= upper_bound)]

# 重复值处理
df = df.drop_duplicates()
```

### 3. 特征工程

```python
# 特征选择
from sklearn.feature_selection import SelectKBest, f_classif

selector = SelectKBest(f_classif, k=10)
X_selected = selector.fit_transform(X, y)

# 特征编码
from sklearn.preprocessing import LabelEncoder, OneHotEncoder

# 标签编码
le = LabelEncoder()
df['category_encoded'] = le.fit_transform(df['category'])

# 独热编码
df = pd.get_dummies(df, columns=['category'])

# 特征缩放
from sklearn.preprocessing import StandardScaler, MinMaxScaler

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 时间特征提取
df['year'] = df['date'].dt.year
df['month'] = df['date'].dt.month
df['day'] = df['date'].dt.day
df['hour'] = df['date'].dt.hour
df['dayofweek'] = df['date'].dt.dayofweek

# 交互特征
df['feature1_x_feature2'] = df['feature1'] * df['feature2']
df['feature1_div_feature2'] = df['feature1'] / (df['feature2'] + 1)
```

### 4. 模型选择与训练

```python
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
import xgboost as xgb

# 划分数据
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# 尝试多个模型
models = {
    'LogisticRegression': LogisticRegression(),
    'RandomForest': RandomForestClassifier(n_estimators=100),
    'XGBoost': xgb.XGBClassifier(),
    'SVM': SVC()
}

for name, model in models.items():
    model.fit(X_train, y_train)
    train_score = model.score(X_train, y_train)
    test_score = model.score(X_test, y_test)
    print(f"{name}: Train={train_score:.4f}, Test={test_score:.4f}")
```

### 5. 模型评估与调优

```python
from sklearn.metrics import (accuracy_score, precision_score, recall_score, 
                            f1_score, roc_auc_score, confusion_matrix,
                            classification_report)

y_pred = model.predict(X_test)
y_prob = model.predict_proba(X_test)[:, 1]

# 分类指标
print(f"Accuracy: {accuracy_score(y_test, y_pred):.4f}")
print(f"Precision: {precision_score(y_test, y_pred):.4f}")
print(f"Recall: {recall_score(y_test, y_pred):.4f}")
print(f"F1: {f1_score(y_test, y_pred):.4f}")
print(f"AUC: {roc_auc_score(y_test, y_prob):.4f}")

# 混淆矩阵
print(confusion_matrix(y_test, y_pred))
print(classification_report(y_test, y_pred))

# 网格搜索调优
from sklearn.model_selection import GridSearchCV

param_grid = {
    'n_estimators': [50, 100, 200],
    'max_depth': [3, 5, 7, 10],
    'learning_rate': [0.01, 0.1, 0.2]
}

grid_search = GridSearchCV(
    xgb.XGBClassifier(),
    param_grid,
    cv=5,
    scoring='accuracy',
    n_jobs=-1
)
grid_search.fit(X_train, y_train)

print(f"Best params: {grid_search.best_params_}")
print(f"Best score: {grid_search.best_score_:.4f}")
```

### 6. 部署与监控

```python
import joblib

# 保存模型
joblib.dump(model, 'model.pkl')

# 加载模型
model = joblib.load('model.pkl')

# 在线预测
def predict(input_data):
    preprocessed = preprocess(input_data)
    prediction = model.predict(preprocessed)
    return prediction

# 模型更新
def update_model(new_data, new_labels):
    model.fit(new_data, new_labels)
    joblib.dump(model, 'model.pkl')
```

---

## 4.2 经典实战项目

### 项目1：房价预测（回归问题）

```python
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.metrics import mean_squared_error, r2_score
import xgboost as xgb

# 1. 加载数据
df = pd.read_csv('house_prices.csv')
print(f"数据形状: {df.shape}")
print(df.head())

# 2. 数据探索
print(df.isnull().sum())
print(df.describe())

# 3. 特征工程
# 选择数值特征
numeric_features = df.select_dtypes(include=[np.number]).columns.tolist()
numeric_features.remove('SalePrice')  # 移除目标变量

X = df[numeric_features]
y = df['SalePrice']

# 处理缺失值
X = X.fillna(X.median())

# 4. 划分数据
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# 5. 特征缩放
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# 6. 训练模型
models = {
    'RandomForest': RandomForestRegressor(n_estimators=100, random_state=42),
    'GradientBoosting': GradientBoostingRegressor(n_estimators=100),
    'XGBoost': xgb.XGBRegressor(n_estimators=100)
}

for name, model in models.items():
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    r2 = r2_score(y_test, y_pred)
    print(f"{name}: RMSE={rmse:.2f}, R2={r2:.4f}")

# 7. 特征重要性
best_model = models['XGBoost']
importance = pd.DataFrame({
    'feature': numeric_features,
    'importance': best_model.feature_importances_
}).sort_values('importance', ascending=False)

print(importance.head(10))
```

### 项目2：泰坦尼克号生存预测（分类问题）

```python
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
import xgboost as xgb

# 1. 加载数据
train_df = pd.read_csv('titanic_train.csv')
test_df = pd.read_csv('titanic_test.csv')

# 2. 数据探索
print(train_df.head())
print(train_df.info())
print(train_df.isnull().sum())

# 3. 特征工程
def preprocess(df):
    df = df.copy()
    
    # 填充缺失值
    df['Age'].fillna(df['Age'].median(), inplace=True)
    df['Embarked'].fillna(df['Embarked'].mode()[0], inplace=True)
    df['Fare'].fillna(df['Fare'].median(), inplace=True)
    
    # 特征提取
    df['Title'] = df['Name'].str.extract(' ([A-Za-z]+)\.', expand=False)
    df['Title'] = df['Title'].replace(['Lady', 'Countess','Capt', 'Col', 'Don', 'Dr', 
                                        'Major', 'Rev', 'Sir', 'Jonkheer', 'Dona'], 'Rare')
    df['Title'] = df['Title'].replace('Mlle', 'Miss')
    df['Title'] = df['Title'].replace('Ms', 'Miss')
    df['Title'] = df['Title'].replace('Mme', 'Mrs')
    
    # 家庭规模
    df['FamilySize'] = df['SibSp'] + df['Parch'] + 1
    df['IsAlone'] = (df['FamilySize'] == 1).astype(int)
    
    # 编码分类变量
    le = LabelEncoder()
    df['Sex'] = le.fit_transform(df['Sex'])
    df['Embarked'] = le.fit_transform(df['Embarked'])
    df['Title'] = le.fit_transform(df['Title'])
    
    # 选择特征
    features = ['Pclass', 'Sex', 'Age', 'SibSp', 'Parch', 'Fare', 
                'Embarked', 'Title', 'FamilySize', 'IsAlone']
    
    return df[features]

X_train = preprocess(train_df)
y_train = train_df['Survived']
X_test = preprocess(test_df)

# 4. 训练模型
model = xgb.XGBClassifier(
    n_estimators=100,
    max_depth=5,
    learning_rate=0.1,
    random_state=42
)
model.fit(X_train, y_train)

# 5. 预测
y_pred = model.predict(X_test)

# 6. 评估（使用验证集）
X_tr, X_val, y_tr, y_val = train_test_split(
    X_train, y_train, test_size=0.2, random_state=42
)
model.fit(X_tr, y_tr)
y_val_pred = model.predict(X_val)

print(f"Validation Accuracy: {accuracy_score(y_val, y_val_pred):.4f}")
print(classification_report(y_val, y_val_pred))
```

### 项目3：客户流失预测

```python
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (accuracy_score, precision_score, recall_score, 
                            f1_score, roc_auc_score, confusion_matrix)
import xgboost as xgb

# 1. 加载数据
df = pd.read_csv('customer_churn.csv')

# 2. 数据预处理
# 编码分类变量
df['Churn'] = df['Churn'].map({'Yes': 1, 'No': 0})
df = pd.get_dummies(df, columns=['Contract', 'PaymentMethod', 'InternetService'])

# 处理缺失值
df = df.fillna(df.median())

# 3. 划分特征和目标
X = df.drop(['customerID', 'Churn'], axis=1)
y = df['Churn']

# 4. 划分数据集（考虑类别不平衡）
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# 5. 特征缩放
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# 6. 训练模型
model = xgb.XGBClassifier(
    n_estimators=200,
    max_depth=6,
    learning_rate=0.1,
    scale_pos_weight=len(y_train[y_train==0])/len(y_train[y_train==1])
)
model.fit(X_train_scaled, y_train)

# 7. 评估
y_pred = model.predict(X_test_scaled)
y_prob = model.predict_proba(X_test_scaled)[:, 1]

print(f"Accuracy: {accuracy_score(y_test, y_pred):.4f}")
print(f"Precision: {precision_score(y_test, y_pred):.4f}")
print(f"Recall: {recall_score(y_test, y_pred):.4f}")
print(f"F1: {f1_score(y_test, y_pred):.4f}")
print(f"AUC: {roc_auc_score(y_test, y_prob):.4f}")
print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred))
```

---

## 4.3 实战技巧

### 交叉验证

```python
from sklearn.model_selection import KFold, StratifiedKFold, cross_val_score

# K折交叉验证
kfold = KFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=kfold, scoring='accuracy')
print(f"K-Fold: {scores.mean():.4f} (+/- {scores.std()*2:.4f})")

# 分层K折（保持类别比例）
skfold = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=skfold, scoring='accuracy')
print(f"Stratified K-Fold: {scores.mean():.4f}")
```

### 类别不平衡处理

```python
from sklearn.utils import resample
from imblearn.over_sampling import SMOTE
from imblearn.under_sampling import RandomUnderSampler

# 方法1：调整类别权重
model = xgb.XGBClassifier(
    scale_pos_weight=ratio  # 负例/正例比例
)

# 方法2：SMOTE过采样
smote = SMOTE(random_state=42)
X_resampled, y_resampled = smote.fit_resample(X_train, y_train)

# 方法3：欠采样
rus = RandomUnderSampler(random_state=42)
X_resampled, y_resampled = rus.fit_resample(X_train, y_train)

# 方法4：组合采样
from imblearn.combine import SMOTETomek
smote_tomek = SMOTETomek(random_state=42)
X_resampled, y_resampled = smote_tomek.fit_resample(X_train, y_train)
```

### 特征缩放

```python
from sklearn.preprocessing import StandardScaler, MinMaxScaler, RobustScaler

# 标准化（均值为0，标准差为1）
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 归一化（0-1范围）
scaler = MinMaxScaler()
X_scaled = scaler.fit_transform(X)

# RobustScaler（对异常值鲁棒）
scaler = RobustScaler()
X_scaled = scaler.fit_transform(X)
```

### 正则化

```python
from sklearn.linear_model import Ridge, Lasso, ElasticNet
from sklearn.ensemble import RandomForestClassifier

# L1正则化（Lasso）
lasso = Lasso(alpha=0.1)
lasso.fit(X_train, y_train)

# L2正则化（Ridge）
ridge = Ridge(alpha=0.1)
ridge.fit(X_train, y_train)

# ElasticNet（L1+L2）
elastic = ElasticNet(alpha=0.1, l1_ratio=0.5)
elastic.fit(X_train, y_train)

# 随机森林中的正则化
rf = RandomForestClassifier(
    max_depth=10,      # 限制树深度
    min_samples_split=5,  # 最小分裂样本数
    min_samples_leaf=2,  # 叶节点最小样本数
    max_features='sqrt'   # 每次分裂考虑的特征数
)
```

---

# 第五章：自然语言处理实战

## 5.1 NLP基础

### 文本预处理

```python
import re
import jieba
from collections import Counter

# 分词
text = "我爱自然语言处理技术"
words = jieba.cut(text)
print(list(words))

# 去除停用词
stopwords = set(['的', '了', '是', '我', '你'])
words = [w for w in words if w not in stopwords]

# 词干提取（英文）
from nltk.stem import PorterStemmer
stemmer = PorterStemmer()
stemmed = stemmer.stem('running')

# 词形还原（英文）
from nltk.stem import WordNetLemmatizer
lemmatizer = WordNetLemmatizer()
lemmatized = lemmatizer.lemmatize('running', 'v')

# 文本清洗
def clean_text(text):
    # 转为小写
    text = text.lower()
    # 去除URL
    text = re.sub(r'http\S+|www\S+', '', text)
    # 去除HTML标签
    text = re.sub(r'<.*?>', '', text)
    # 去除特殊字符
    text = re.sub(r'[^a-zA-Z0-9\s]', '', text)
    # 去除多余空格
    text = re.sub(r'\s+', ' ', text).strip()
    return text
```

### 词向量

```python
from gensim.models import Word2Vec, FastText
import numpy as np

# 准备训练数据
sentences = [['我', '爱', '自然语言', '处理'],
             ['深度', '学习', '是', '人工', '智能'],
             ['机器', '学习', '很', '重要']]

# 训练Word2Vec
model = Word2Vec(sentences, vector_size=100, window=5, min_count=1, workers=4)

# 获取词向量
vector = model.wv['机器']
print(f"词向量维度: {vector.shape}")

# 找相似词
similar = model.wv.most_similar('机器', topn=3)
print(similar)

# FastText（处理未登录词）
fasttext_model = FastText(sentences, vector_size=100, window=5, min_count=1)
```

---

## 5.2 传统NLP方法

### TF-IDF + 分类器

```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.linear_model import LogisticRegression
from sklearn.svm import LinearSVC

# TF-IDF向量化
tfidf = TfidfVectorizer(
    max_features=5000,
    ngram_range=(1, 2),  # unigram + bigram
    min_df=2,
    max_df=0.95
)
X_tfidf = tfidf.fit_transform(corpus)

# 朴素贝叶斯
nb = MultinomialNB()
nb.fit(X_tfidf, labels)

# 逻辑回归
lr = LogisticRegression(max_iter=1000)
lr.fit(X_tfidf, labels)

# SVM
svm = LinearSVC()
svm.fit(X_tfidf, labels)
```

### 关键词提取

```python
import jieba.analyse

# TF-IDF关键词提取
keywords_tfidf = jieba.analyse.extract_tags(text, topK=10, withWeight=True)
print(keywords_tfidf)

# TextRank关键词提取
keywords_textrank = jieba.analyse.textrank(text, topK=10, withWeight=True)
print(keywords_textrank)
```

---

## 5.3 深度学习NLP

### 使用PyTorch实现文本分类

```python
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import numpy as np

class TextClassificationModel(nn.Module):
    def __init__(self, vocab_size, embed_dim, num_class):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, embed_dim, padding_idx=0)
        self.fc = nn.Linear(embed_dim, num_class)
    
    def forward(self, x):
        embedded = self.embedding(x)
        # 平均池化
        pooled = torch.mean(embedded, dim=1)
        return self.fc(pooled)

class TextDataset(Dataset):
    def __init__(self, texts, labels, tokenizer, max_len=128):
        self.texts = texts
        self.labels = labels
        self.tokenizer = tokenizer
        self.max_len = max_len
    
    def __len__(self):
        return len(self.texts)
    
    def __getitem__(self, idx):
        text = self.texts[idx]
        label = self.labels[idx]
        
        encoding = self.tokenizer(
            text,
            max_length=self.max_len,
            padding='max_length',
            truncation=True,
            return_tensors='pt'
        )
        
        return {
            'input_ids': encoding['input_ids'].squeeze(),
            'label': torch.tensor(label, dtype=torch.long)
        }

# 训练
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = TextClassificationModel(vocab_size=10000, embed_dim=128, num_class=2)
model.to(device)

optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
criterion = nn.CrossEntropyLoss()

for epoch in range(10):
    for batch in dataloader:
        input_ids = batch['input_ids'].to(device)
        labels = batch['label'].to(device)
        
        optimizer.zero_grad()
        outputs = model(input_ids)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
```

### Transformer文本分类

```python
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

# 加载预训练模型
model_name = 'bert-base-chinese'
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(
    model_name, num_labels=2
)

# 编码文本
inputs = tokenizer(text, return_tensors='pt', padding=True, truncation=True, max_length=128)

# 预测
with torch.no_grad():
    outputs = model(**inputs)
    predictions = torch.argmax(outputs.logits, dim=-1)
```

---

## 5.4 NLP实战项目

### 项目1：情感分析

```python
from transformers import pipeline

# 使用预训练模型进行情感分析
sentiment_analyzer = pipeline("sentiment-analysis", model="uer/roberta-base-finetuned-chinanews-chinese")

# 分析单条文本
result = sentiment_analyzer("这个产品非常好用，强烈推荐！")
print(result)  # [{'label': 'POSITIVE', 'score': 0.99}]

# 分析多条文本
results = sentiment_analyzer([
    "东西还不错，物流很快",
    "太差了，完全不推荐",
    "一般般，没有想象中好"
])
```

### 项目2：文本摘要

```python
from transformers import pipeline

# 文本摘要
summarizer = pipeline("summarization", model="IDEA-CCNL/Randeng-Pegasus-238M-Chinese")

text = """
人工智能是计算机科学的一个分支，致力于开发能够执行通常需要人类智能的任务的系统。
这包括视觉感知、语音识别、决策制定和语言翻译等。机器学习是人工智能的一个子集，
它使系统能够从数据中学习和改进，而无需明确编程。深度学习是机器学习的一个分支，
它使用具有多个层的神经网络来逐步学习数据的高级特征。
"""

summary = summarizer(text, max_length=100, min_length=30)
print(summary[0]['summary_text'])
```

### 项目3：命名实体识别（NER）

```python
from transformers import pipeline

# NER任务
ner = pipeline("ner", model="dslim/bert-base-NER", aggregation_strategy="simple")

text = "Elon Musk is the CEO of SpaceX and Tesla, Inc., founded in 2002."
entities = ner(text)

for entity in entities:
    print(f"{entity['word']}: {entity['entity_group']} ({entity['score']:.3f})")
```

---

# 第六章：图像识别实战

## 6.1 计算机视觉基础

### 图像读取与预处理

```python
import cv2
import numpy as np
from PIL import Image
import matplotlib.pyplot as plt

# 使用OpenCV读取
img = cv2.imread('image.jpg')
img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

# 使用PIL读取
img = Image.open('image.jpg')
img_array = np.array(img)

# 图像缩放
resized = cv2.resize(img, (224, 224))

# 归一化（ImageNet统计量）
mean = np.array([0.485, 0.456, 0.406])
std = np.array([0.229, 0.224, 0.225])
normalized = (img / 255.0 - mean) / std
```

### 数据增强

```python
import torchvision.transforms as transforms

train_transform = transforms.Compose([
    transforms.RandomResizedCrop(224),
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(15),
    transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                        std=[0.229, 0.224, 0.225])
])

val_transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                        std=[0.229, 0.224, 0.225])
])
```

---

## 6.2 CNN图像分类

### 使用PyTorch实现CNN

```python
import torch
import torch.nn as nn
import torch.nn.functional as F

class CNN(nn.Module):
    def __init__(self, num_classes=10):
        super(CNN, self).__init__()
        
        # 卷积层
        self.conv1 = nn.Conv2d(3, 32, kernel_size=3, padding=1)
        self.conv2 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
        self.conv3 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        
        # 池化层
        self.pool = nn.MaxPool2d(2, 2)
        
        # 全连接层
        self.fc1 = nn.Linear(128 * 28 * 28, 512)
        self.fc2 = nn.Linear(512, num_classes)
        
        # Dropout
        self.dropout = nn.Dropout(0.5)
    
    def forward(self, x):
        # Conv block 1: 3x224x224 -> 32x112x112
        x = self.pool(F.relu(self.conv1(x)))
        
        # Conv block 2: 32x112x112 -> 64x56x56
        x = self.pool(F.relu(self.conv2(x)))
        
        # Conv block 3: 64x56x56 -> 128x28x28
        x = self.pool(F.relu(self.conv3(x)))
        
        # Flatten
        x = x.view(x.size(0), -1)
        
        # FC
        x = self.dropout(F.relu(self.fc1(x)))
        x = self.fc2(x)
        
        return x
```

### 使用迁移学习

```python
import torchvision.models as models
import torch.nn as nn

# 方法1：使用预训练模型并微调
model = models.resnet50(pretrained=True)

# 冻结前面的层
for param in model.parameters():
    param.requires_grad = False

# 替换最后的全连接层
num_features = model.fc.in_features
model.fc = nn.Linear(num_features, 10)  # 10类分类

# 方法2：使用torchvision内置的预训练模型
from torchvision import models
model = models.efficientnet_b0(pretrained=True)

# 修改分类头
model.classifier[1] = nn.Linear(model.classifier[1].in_features, 10)
```

---

## 6.3 目标检测

### 使用YOLO进行目标检测

```python
import cv2
import numpy as np

# 加载YOLO
net = cv2.dnn.readNetFromDarknet('yolov3.cfg', 'yolov3.weights')
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)

# 读取图像
img = cv2.imread('image.jpg')
blob = cv2.dnn.blobFromImage(img, 1/255.0, (416, 416), swapRB=True, crop=False)

# 前向传播
net.setInput(blob)
layer_names = net.getLayerNames()
output_layers = [layer_names[i - 1] for i in net.getUnconnectedOutLayers()]
outputs = net.forward(output_layers)

# 解析检测结果
class_ids = []
confidences = []
boxes = []

for output in outputs:
    for detection in output:
        scores = detection[5:]
        class_id = np.argmax(scores)
        confidence = scores[class_id]
        
        if confidence > 0.5:
            center_x = int(detection[0] * img.shape[1])
            center_y = int(detection[1] * img.shape[0])
            w = int(detection[2] * img.shape[1])
            h = int(detection[3] * img.shape[0])
            
            boxes.append([center_x - w//2, center_y - h//2, w, h])
            confidences.append(float(confidence))
            class_ids.append(class_id)
```

### 使用预训练Detectron2

```python
from detectron2.engine import DefaultPredictor
from detectron2.config import get_cfg
from detectron2 import model_zoo

# 配置
cfg = get_cfg()
cfg.merge_from_file(model_zoo.get_config_file("COCO-Detection/faster_rcnn_R_50_FPN_3x.yaml"))
cfg.MODEL.WEIGHTS = model_zoo.get_checkpoint_url("COCO-Detection/faster_rcnn_R_50_FPN_3x.yaml")

# 预测器
predictor = DefaultPredictor(cfg)
outputs = predictor(image)

# 解析结果
boxes = outputs["instances"].pred_boxes.tensor.cpu().numpy()
scores = outputs["instances"].scores.cpu().numpy()
classes = outputs["instances"].pred_classes.cpu().numpy()
```

---

## 6.4 图像分割

### U-Net图像分割

```python
import torch
import torch.nn as nn
import torch.nn.functional as F

class UNet(nn.Module):
    def __init__(self, in_channels=3, out_channels=1):
        super(UNet, self).__init__()
        
        # 编码器
        self.enc1 = self._block(in_channels, 64)
        self.pool1 = nn.MaxPool2d(2)
        
        self.enc2 = self._block(64, 128)
        self.pool2 = nn.MaxPool2d(2)
        
        self.enc3 = self._block(128, 256)
        self.pool3 = nn.MaxPool2d(2)
        
        self.enc4 = self._block(256, 512)
        self.pool4 = nn.MaxPool2d(2)
        
        # 瓶颈
        self.bottleneck = self._block(512, 1024)
        
        # 解码器
        self.up4 = nn.ConvTranspose2d(1024, 512, kernel_size=2, stride=2)
        self.dec4 = self._block(1024, 512)
        
        self.up3 = nn.ConvTranspose2d(512, 256, kernel_size=2, stride=2)
        self.dec3 = self._block(512, 256)
        
        self.up2 = nn.ConvTranspose2d(256, 128, kernel_size=2, stride=2)
        self.dec2 = self._block(256, 128)
        
        self.up1 = nn.ConvTranspose2d(128, 64, kernel_size=2, stride=2)
        self.dec1 = self._block(128, 64)
        
        # 输出
        self.out = nn.Conv2d(64, out_channels, kernel_size=1)
    
    def _block(self, in_ch, out_ch):
        return nn.Sequential(
            nn.Conv2d(in_ch, out_ch, kernel_size=3, padding=1),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_ch, out_ch, kernel_size=3, padding=1),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True)
        )
    
    def forward(self, x):
        # 编码
        e1 = self.enc1(x)
        e2 = self.enc2(self.pool1(e1))
        e3 = self.enc3(self.pool2(e2))
        e4 = self.enc4(self.pool3(e3))
        
        # 瓶颈
        b = self.bottleneck(self.pool4(e4))
        
        # 解码
        d4 = self.dec4(torch.cat([self.up4(b), e4], dim=1))
        d3 = self.dec3(torch.cat([self.up3(d4), e3], dim=1))
        d2 = self.dec2(torch.cat([self.up2(d3), e2], dim=1))
        d1 = self.dec1(torch.cat([self.up1(d2), e1], dim=1))
        
        return torch.sigmoid(self.out(d1))
```

---

# 第七章：大模型基础

## 7.1 大语言模型发展历程

### NLP发展历程

```
1950s-1980s: 规则系统 → 基于知识的方法
1990s-2010s: 统计学习 → 词袋模型、SVM、HMM、CRF
2013-2017: 词向量 → Word2Vec、GloVe
2017-2020: 预训练+微调 → BERT、GPT系列
2020-至今: 大模型时代 → GPT-4、Claude、LLaMA等
```

### GPT系列发展

| 版本 | 发布时间 | 参数规模 | 特点 |
|------|---------|---------|------|
| GPT-1 | 2018 | 1.17亿 | 首个Transformer语言模型 |
| GPT-2 | 2019 | 15亿 | 零样本学习、多任务 |
| GPT-3 | 2020 | 1750亿 | 上下文学习、few-shot |
| GPT-3.5 | 2022 | 1750亿 | RLHF、ChatGPT |
| GPT-4 | 2023 | ~1.7万亿 | 多模态、更长上下文 |

### 开源大模型

- **LLaMA** (Meta): 高效开源基座
- **ChatGLM** (清华): 中文优化开源
- **Qwen** (阿里): 中英文双语
- **Baichuan** (百川): 中文开源
- **Mistral** (欧洲): 高性能

---

## 7.2 大模型核心技术

### 预训练任务

#### Next Token Prediction
GPT系列使用的预训练目标：
```
给定前文，预测下一个token
P(w_t | w_1, w_2, ..., w_{t-1})
```

#### Masked Language Model (MLM)
BERT使用的预训练目标：
```
15% tokens mask，预测被mask的token
```

### 涌现能力

大模型在参数规模超过一定阈值后，突然出现小模型不具备的能力：

- **推理能力**：逐步思考、逻辑推理
- **思维链**：Chain-of-Thought
- **指令遵循**：遵循复杂指令
- **上下文学习**：无需微调学习新任务

### 指令微调 (SFT)

将预训练模型微调为遵循指令的模型：
```python
# 指令微调数据格式
{
    "instruction": "请总结以下文章的要点：",
    "input": "文章内容...",
    "output": "总结内容..."
}
```

### RLHF

人类反馈强化学习三步骤：

1. **SFT微调**：使用人工编写的问答对微调
2. **训练奖励模型**：人类对输出排序，训练奖励模型
3. **PPO强化学习**：用奖励模型指导模型优化

```python
# RLHF流程
# Step 1: Supervised Fine-Tuning
sft_model = fine_tune(base_model, sft_data)

# Step 2: Reward Model Training
reward_model = train_reward_model(sft_outputs, human_feedback)

# Step 3: PPO
ppo_model = train_with_ppo(reward_model, sft_model)
```

---

## 7.3 大模型能力评估

### 主流评测基准

| 基准 | 评估能力 | 代表模型 |
|------|---------|---------|
| **MMLU** | 57个学科的理解 | GPT-4、Claude |
| **HumanEval** | 代码能力 | CodeLlama |
| **GSM8K/MATH** | 数学推理 | GPT-4 |
| **TriviaQA** | 知识问答 | 大模型 |
| **Chatbot Arena** | 对话体验 | LLM Elo排名 |

### 中文评测基准

- **CMMLU**: 中文多任务理解
- **C-Eval**: 中文综合能力
- **MOSS**: 中文对话能力

---

## 7.4 大模型局限性

### 幻觉问题

大模型可能生成看似合理但实际错误的内容。

**缓解方法：**
- RAG（检索增强）
- 事实核查
- CoT提示减少幻觉

### 知识截止

模型知识有时间限制，无法获取最新信息。

**解决方案：**
- 联网搜索
- RAG实时检索
- 定期微调

### 计算成本

大模型推理需要大量GPU资源。

**优化方案：**
- 模型量化（INT8/INT4）
- 蒸馏小模型
- 推理优化（vLLM）

---

# 第八章：大模型实战

## 8.1 Prompt工程

### 基础Prompt技巧

```python
# 零样本提示 (Zero-shot)
prompt = "判断以下评论的情感：'这个产品太棒了！'"
# 无示例，直接要求

# 少样本提示 (Few-shot)
prompt = """
判断情感：
产品很好用 -> 正面
东西太差了 -> 负面
服务态度一般 -> {}
"""
# 提供示例，让模型学习模式

# 思维链提示 (CoT)
prompt = """
问题：小明有5个苹果，小红给他3个，小明吃了2个，还剩多少个？
让我们一步步思考：
1. 小明最初有5个苹果
2. 小红给了他3个，所以有5+3=8个
3. 小明吃了2个，所以剩下8-2=6个
答案是：6个
"""
```

### Prompt设计原则

1. **明确任务**：清晰说明要做什么
2. **提供示例**：Few-shot帮助理解
3. **分解步骤**：复杂问题分步处理
4. **格式要求**：指定输出格式
5. **角色设定**：设定角色提升专业性

```python
# 结构化输出
prompt = """
作为数据分析专家，请分析以下销售数据。

数据：{sales_data}

请以JSON格式输出：
{{
    "total_revenue": 总销售额,
    "growth_rate": 增长率,
    "top_products": [{{"name": "产品名", "sales": 销量}}],
    "insights": ["洞察1", "洞察2"]
}}
"""
```

---

## 8.2 LLM应用开发

### OpenAI API调用

```python
from openai import OpenAI

client = OpenAI(api_key="your-api-key")

# 基础对话
response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": "你是一个专业的AI助手"},
        {"role": "user", "content": "解释什么是机器学习"}
    ],
    temperature=0.7,
    max_tokens=1000
)

print(response.choices[0].message.content)

# 流式输出
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "写一个故事"}],
    stream=True
)

for chunk in response:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")

# 函数调用
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "今天北京天气如何？"}],
    tools=[{
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "获取指定城市的天气",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "城市名称"}
                },
                "required": ["city"]
            }
        }
    }]
)
```

### 使用LangChain

```python
from langchain.chat_models import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage
from langchain.prompts import ChatPromptTemplate
from langchain.chains import LLMChain
from langchain.agents import AgentExecutor, load_tools
from langchain.memory import ConversationBufferMemory

# 初始化
llm = ChatOpenAI(model_name="gpt-4", temperature=0.7)

# 简单对话
chat = llm([
    SystemMessage(content="你是一个专业的Python编程助手"),
    HumanMessage(content="如何实现快速排序？")
])

# 使用Prompt模板
prompt = ChatPromptTemplate.from_template(
    "请用{language}实现{algorithm}算法"
)

chain = LLMChain(llm=llm, prompt=prompt)
result = chain.run(language="Python", algorithm="快速排序")
print(result)

# 加载工具
tools = load_tools(["serpapi", "llm-math"], llm=llm)

# Agent
from langchain.agents import initialize_agent
agent = initialize_agent(
    tools, llm, agent="zero-shot-react-description", verbose=True
)
agent.run("查找2024年诺贝尔物理学奖获得者并计算他们年龄之和")
```

### 使用LlamaIndex

```python
from llama_index import GPTSimpleVectorIndex, SimpleDirectoryReader

# 加载文档
documents = SimpleDirectoryReader('data').load_data()

# 构建索引
index = GPTSimpleVectorIndex.from_documents(documents)

# 查询
response = index.query("关于文档中提到的核心技术点是什么？")
print(response)
```

---

## 8.3 RAG技术

### 完整RAG流程

```python
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.chains import RetrievalQA
from langchain.chat_models import ChatOpenAI

# 1. 文档加载
from langchain.document_loaders import PyPDFLoader
loader = PyPDFLoader("document.pdf")
pages = loader.load_and_split()

# 2. 文本分割
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200
)
docs = text_splitter.split_documents(pages)

# 3. 向量化
embeddings = OpenAIEmbeddings()
vectorstore = Chroma.from_documents(docs, embeddings)

# 4. 构建RAG链
qa = RetrievalQA.from_chain_type(
    llm=ChatOpenAI(model_name="gpt-4"),
    chain_type="stuff",
    retriever=vectorstore.as_retriever()
)

# 5. 问答
result = qa({"query": "文档中关于xxx的描述是什么？"})
print(result['result'])
```

### 常用向量数据库

```python
# Chroma（轻量级）
from langchain.vectorstores import Chroma
db = Chroma.from_documents(docs, embeddings)

# Milvus（大规模生产环境）
from pymilvus import connections, Collection
connections.connect("default", host="localhost", port="19530")

# Pinecone（云服务）
from pinecone import Pinecone
pc = Pinecone(api_key="your-api-key")
index = pc.Index("your-index")
```

---

## 8.4 大模型微调

### LoRA微调

```python
from peft import LoraConfig, get_peft_model, TaskType
from transformers import AutoModelForCausalLM, AutoTokenizer

# 加载基座模型
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    load_in_8bit=True,
    device_map="auto"
)
tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-2-7b-hf")

# 配置LoRA
lora_config = LoraConfig(
    r=8,  # LoRA rank
    lora_alpha=16,
    target_modules=["q_proj", "v_proj"],  # 要替换的模块
    lora_dropout=0.05,
    bias="none",
    task_type=TaskType.CAUSAL_LM
)

# 应用LoRA
model = get_peft_model(model, lora_config)
model.print_trainable_parameters()
# 输出: trainable params: 4,194,304 || all params: 6,742,609,280 || trainable%: 0.062

# 训练
from transformers import Trainer, TrainingArguments

training_args = TrainingArguments(
    output_dir="./output",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    learning_rate=3e-4,
    fp16=True,
    save_strategy="epoch",
    save_total_limit=2
)

trainer = Trainer(
    model=model,
    train_dataset=train_dataset,
    args=training_args
)

trainer.train()
```

### QLoRA微调（更高效率）

```python
# QLoRA使用NF4量化 + LoRA
from peft import LoraConfig, get_peft_model
from transformers import AutoModelForCausalLM, BitsAndBytesConfig

# 4位量化配置
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype="float16",
    bnb_4bit_use_double_quant=True,
    bnb_4bit_quant_type="nf4"
)

# 加载量化模型
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    quantization_config=bnb_config,
    device_map="auto"
)

# 应用LoRA（同上）
model = get_peft_model(model, lora_config)
```

---

## 8.5 Agent与工具使用

### ReAct Agent实现

```python
from langchain.agents import AgentExecutor, create_react_agent
from langchain import hub
from langchain.tools import Tool

# 定义工具
def search_function(query):
    # 搜索功能实现
    return f"搜索结果: {query}"

def calculator(expression):
    # 计算功能实现
    return eval(expression)

tools = [
    Tool(
        name="Search",
        func=search_function,
        description="用于搜索信息"
    ),
    Tool(
        name="Calculator",
        func=calculator,
        description="用于数学计算"
    )
]

# 加载ReAct prompt
prompt = hub.pull("hwchase17/react")

# 创建Agent
agent = create_react_agent(llm, tools, prompt)
agent_executor = AgentExecutor(
    agent=agent,
    tools=tools,
    verbose=True,
    max_iterations=10
)

# 执行
result = agent_executor.invoke({
    "input": "查找2024年世界杯冠军，然后计算他们的获胜年份之和"
})
```

### Tool Use（函数调用）

```python
# 定义工具函数
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "获取指定城市的天气信息",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "城市名称"}
                },
                "required": ["city"]
            }
        }
    },
    {
        "type": "function", 
        "function": {
            "name": "send_email",
            "description": "发送邮件",
            "parameters": {
                "type": "object",
                "properties": {
                    "to": {"type": "string"},
                    "subject": {"type": "string"},
                    "body": {"type": "string"}
                },
                "required": ["to", "subject", "body"]
            }
        }
    }
]

# 调用并处理
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "北京明天天气怎么样？"}],
    tools=tools
)

# 处理工具调用
tool_calls = response.choices[0].message.tool_calls
for call in tool_calls:
    if call.function.name == "get_weather":
        args = json.loads(call.function.arguments)
        result = get_weather(args["city"])
```

---

# 附录A：算法使用场景对比

## 传统机器学习算法

| 算法 | 类型 | 最佳使用场景 | 不适用场景 |
|------|------|-------------|-----------|
| **线性回归** | 回归 | 连续值预测、趋势分析、特征与目标呈线性关系 | 非线性关系、分类问题 |
| **逻辑回归** | 分类 | 二分类、概率预测、需要可解释性 | 多分类（可使用OvR）、复杂非线性 |
| **决策树** | 分类/回归 | 规则清晰、可解释性强、特征重要性分析 | 容易过拟合、对数据噪声敏感 |
| **随机森林** | 分类/回归 | 分类/回归竞赛、特征重要性分析、抗过拟合 | 训练时间长、对不平衡数据敏感 |
| **梯度提升树(XGBoost/LightGBM)** | 分类/回归 | 表格数据竞赛、性能要求高、特征工程 | 图像/文本等非结构化数据 |
| **SVM** | 分类 | 高维小样本、文本分类、复杂边界 | 大规模数据、多分类 |
| **KNN** | 分类/回归 | 简单基准、多标签分类、推荐系统 | 高维数据、实时性要求高 |
| **K-means** | 聚类 | 客户分群、图像压缩、异常检测 | 非球形簇、需预设K值 |
| **层次聚类** | 聚类 | 层次结构分析、文档归类 | 大规模数据 |
| **朴素贝叶斯** | 分类 | 文本分类、垃圾邮件、多分类 | 特征相关性强的场景 |

## 深度学习算法

| 算法 | 类型 | 最佳使用场景 | 不适用场景 |
|------|------|-------------|-----------|
| **MLP(多层感知机)** | 分类/回归 | 表格数据、简单非线性、深度学习入门 | 序列/图像数据、参数太多 |
| **CNN** | 图像/视频 | 图像分类、目标检测、图像分割 | 序列数据、需要可解释性 |
| **RNN/LSTM/GRU** | 序列 | 时间序列、NLP、语音识别 | 并行计算要求高、长依赖 |
| **Transformer** | 序列/多模态 | NLP、机器翻译、文本生成、图像处理 | 资源受限场景 |
| **GAN** | 生成 | 图像生成、数据增强、艺术创作 | 训练不稳定、需要大量数据 |
| **VAE** | 生成 | 图像生成、异常检测、潜空间探索 | 追求高画质生成 |

---

# 附录B：实际应用场景

## 生活中的AI应用

| 场景 | 具体应用 | 使用的AI技术 |
|------|---------|-------------|
| **推荐系统** | 抖音/小红书内容推荐、淘宝商品推荐 | 协同过滤、深度学习推荐模型 |
| **语音助手** | 小爱同学、Siri、小度 | ASR语音识别、NLP理解、TTS语音合成 |
| **拍照摄影** | 人像美颜、夜景优化、物体识别 | CNN图像处理、目标检测 |
| **地图导航** | 路线规划ETA、实时路况预测 | 时间序列预测、强化学习 |
| **智能客服** | 电商售后、银行咨询 | NLP对话系统、大语言模型 |
| **内容审核** | 色情/暴力内容过滤 | 图像分类、NLP文本分类 |
| **刷脸支付** | 支付宝、微信支付人脸验证 | 人脸识别、活体检测 |
| **智能相册** | 按人物/地点/事件分类照片 | 人脸识别、图像分割 |
| **垃圾邮件过滤** | 邮箱垃圾邮件自动分类 | 文本分类、朴素贝叶斯/SVM |
| **智能写作** | Grammarly语法纠错、摘要生成 | NLP文本生成、Transformer |
| **智能翻译** | Google翻译、DeepL | Seq2Seq、Transformer |
| **修图软件** | 一键消除路人、AI换背景 | 图像分割、图像生成 |
| **智能家居** | 语音控制、异常检测 | 语音识别、时序异常检测 |
| **健康监测** | 智能手表心率预警、睡眠分析 | 时序分析、可穿戴设备ML |
| **游戏** | AI对手、智能辅助 | 强化学习、计算机视觉 |

## 工作中的AI应用

| 行业 | 应用场景 | 使用的AI技术 |
|------|---------|-------------|
| **金融** | 信用卡欺诈检测、风控评估、量化交易 | 异常检测、XGBoost、时间序列 |
| **医疗** | 影像辅助诊断、药物研发、病历分析 | CNN医学影像、NLP、图神经网络 |
| **零售** | 销量预测、库存管理、个性化营销 | 时序预测、推荐系统、聚类 |
| **制造** | 质量检测、设备故障预测、供应链优化 | 目标检测、预测性维护、强化学习 |
| **教育** | 智能批改、自适应学习、学情分析 | NLP、推荐系统、知识图谱 |
| **法律** | 合同审核、案例检索、法条推荐 | NLP、文本相似度、检索 |
| **人力资源** | 简历筛选、员工流失预测、面试评估 | 文本分类、预测模型 |
| **营销** | 用户画像、广告投放优化、AB测试 | 聚类、推荐系统、统计分析 |
| **客服** | 智能客服、工单分类、满意度分析 | 对话系统、文本分类、情感分析 |
| **安全** | 入侵检测、威胁识别、视频监控 | 异常检测、目标检测、时序分析 |
| **媒体** | 内容推荐、内容生成、版权检测 | 推荐系统、NLP生成、图像识别 |
| **物流** | 路径优化、需求预测、无人配送 | 强化学习、预测模型、规划算法 |
| **能源** | 电网负荷预测、设备维护、异常检测 | 时序预测、异常检测 |
| **房地产** | 房价预测、房产评估、客户画像 | 回归模型、聚类、推荐系统 |
| **政府** | 智慧城市、应急管理、政务服务 | 多模态感知、数据分析、预测 |

## 典型AI产品技术拆解

| 产品 | 核心技术栈 |
|------|----------|
| **ChatGPT** | Transformer、RLHF、Prompt Engineering、向量检索 |
| **Midjourney** | Diffusion Model、CLIP、Prompt Engineering |
| **特斯拉自动驾驶** | CNN目标检测、BEV感知、Transformer规划、强化学习 |
| **抖音推荐** | 深度学习推荐模型(DIN、DIEN)、Embedding、在线学习 |
| **GPT-4代码助手** | CodeGen模型、代码检索、AST解析 |
| **人脸门禁** | 人脸检测、MTCNN、FaceNet/ArcFace、活体检测 |
| **智能写作助手** | LLM、文本生成、RAG、知识库 |
| **AI虚拟主播** | 语音合成(TTS)、数字人驱动、唇形同步、NLP |

---

# 学习建议

## 阶段安排

| 阶段 | 建议时长 | 重点 |
|------|---------|------|
| 机器学习入门 | 4-6周 | 数学基础、经典算法、评估指标 |
| 深度学习基础 | 4-6周 | 神经网络原理、CNN/RNN/Transformer |
| 框架与库 | 2-4周 | NumPy、Pandas、Scikit-learn、PyTorch |
| 机器学习实战 | 4-6周 | 完整项目流程、工程化能力 |
| NLP实战 | 4-6周 | 文本处理、深度学习NLP |
| 图像识别实战 | 4-6周 | CNN、迁移学习、目标检测 |
| 大模型基础 | 2-4周 | LLM原理、评估、微调理论 |
| 大模型实战 | 4-8周 | Prompt工程、LangChain、RAG、Agent |

## 学习资源

- **书籍**：《机器学习西瓜书》、《深度学习花书》、《Python机器学习》、《大规模语言模型》
- **在线课程**：吴恩达机器学习/深度学习系列、李宏毅机器学习、CS224N、CS231N
- **实践平台**：Kaggle、天池、阿里云PAI
- **论文**：关注NeurIPS、ICML、CVPR、ACL、ICLR、EMNLP顶会

## 关键能力培养

- **数学思维**：理解算法背后的原理，而非只会调库
- **工程能力**：代码规范、版本控制、文档撰写
- **问题分析**：从业务问题到技术方案的转化
- **持续学习**：AI领域发展迅速，保持技术敏感度

---

> **提示**：本教程建议每个模块都动手实践，积累完整项目经验，这对于求职和技能提升至关重要。

NumPy是Python科学计算的基础库，提供高效的数组和矩阵运算。

```python
import numpy as np

# 创建数组
arr = np.array([1, 2, 3, 4, 5])
matrix = np.array([[1, 2], [3, 4]])

# 数组运算
arr * 2           # [2, 4, 6, 8, 10]
arr + arr         # [2, 4, 6, 8, 10]
np.dot(arr, arr)  # 点积

# 矩阵运算
np.matmul(matrix, matrix)  # 矩阵乘法
matrix.T                     # 转置
np.linalg.eig(matrix)       # 特征值分解

# 随机数
np.random.rand(3, 3)        # 0-1均匀分布
np.random.randn(3, 3)       # 标准正态分布
np.random.choice(arr, 3)     # 随机选择
```

### Pandas

Pandas用于数据处理和分析，核心数据结构是DataFrame。

```python
import pandas as pd

# 读取数据
df = pd.read_csv('data.csv')
df = pd.read_excel('data.xlsx')

# 基本操作
df.head()           # 查看前几行
df.info()            # 数据信息
df.describe()       # 统计描述
df.shape            # 数据维度
df.columns          # 列名

# 数据选择
df['column']        # 选择单列
df[['col1', 'col2']]  # 选择多列
df.iloc[0:5]        # 位置索引
df.loc[0:5]         # 标签索引

# 数据清洗
df.isnull()         # 缺失值
df.dropna()        # 删除缺失值
df.fillna(0)       # 填充缺失值
df.drop_duplicates()  # 删除重复

# 数据转换
df['col'] = df['col'].astype(str)
df['col'] = pd.to_datetime(df['col'])

# 分组聚合
df.groupby('category').agg({'price': 'mean', 'quantity': 'sum'})

# 合并数据
pd.merge(df1, df2, on='key')
pd.concat([df1, df2])
```

### Matplotlib / Seaborn

数据可视化库。

```python
import matplotlib.pyplot as plt
import seaborn as sns

# 折线图
plt.plot(x, y)
plt.show()

# 散点图
plt.scatter(x, y)
plt.xlabel('X')
plt.ylabel('Y')
plt.title('Title')

# 柱状图
plt.bar(categories, values)

# 直方图
plt.hist(data, bins=30)

# 箱线图
plt.boxplot([data1, data2], labels=['A', 'B'])

# Seaborn快速绘图
sns.lineplot(data=df, x='date', y='value')
sns.heatmap(correlation_matrix, annot=True)
sns.pairplot(df)
```

---

## 3.2 机器学习框架：Scikit-learn

Scikit-learn提供统一的机器学习API。

### 核心API

```python
from sklearn import model_selection, preprocessing, metrics

# 划分数据集
X_train, X_test, y_train, y_test = model_selection.train_test_split(
    X, y, test_size=0.2, random_state=42
)

# 特征缩放
scaler = preprocessing.StandardScaler()  # 标准化
# scaler = preprocessing.MinMaxScaler()  # 归一化
scaler.fit(X_train)
X_train_scaled = scaler.transform(X_train)
X_test_scaled = scaler.transform(X_test)

# 模型训练与预测
model = SomeModel()
model.fit(X_train, y_train)
y_pred = model.predict(X_test)

# 评估
accuracy = metrics.accuracy_score(y_test, y_pred)
report = metrics.classification_report(y_test, y_pred)
```

### 完整pipeline

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression

pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('classifier', LogisticRegression())
])

pipeline.fit(X_train, y_train)
y_pred = pipeline.predict(X_test)
```

### 交叉验证

```python
from sklearn.model_selection import cross_val_score

scores = cross_val_score(model, X, y, cv=5, scoring='accuracy')
print(f"Mean: {scores.mean():.3f}, Std: {scores.std():.3f}")
```

---

## 3.3 深度学习框架

### TensorFlow / Keras

```python
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

# 使用Keras Sequential API
model = keras.Sequential([
    layers.Dense(64, activation='relu', input_shape=(784,)),
    layers.Dropout(0.2),
    layers.Dense(10, activation='softmax')
])

model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# 训练
model.fit(X_train, y_train, epochs=10, validation_split=0.1)

# 评估
model.evaluate(X_test, y_test)

# 预测
predictions = model.predict(X_test)
```

### PyTorch

```python
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset

# 定义模型
class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.fc1 = nn.Linear(784, 64)
        self.fc2 = nn.Linear(64, 10)
    
    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = self.fc2(x)
        return x

# 准备数据
X_tensor = torch.FloatTensor(X_train)
y_tensor = torch.LongTensor(y_train)
dataset = TensorDataset(X_tensor, y_tensor)
loader = DataLoader(dataset, batch_size=32, shuffle=True)

# 训练
model = Net()
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

for epoch in range(10):
    for batch_x, batch_y in loader:
        optimizer.zero_grad()
        outputs = model(batch_x)
        loss = criterion(outputs, batch_y)
        loss.backward()
        optimizer.step()
```

### JAX

```python
import jax
import jax.numpy as jnp
from jax import grad, jit

# 自动微分
def loss_fn(params, x, y):
    pred = jnp.dot(x, params['w']) + params['b']
    return jnp.mean((pred - y) ** 2)

grad_fn = jit(grad(loss_fn))

# 更新参数
params = {'w': jnp.zeros((784, 10)), 'b': jnp.zeros(10)}
grads = grad_fn(params, x_batch, y_batch)
params = jax.tree_util.tree_map(lambda p, g: p - 0.001 * g, params, grads)
```

---

## 3.4 特色工具库

### XGBoost / LightGBM

梯度提升树的优化实现。

```python
import xgboost as xgb
import lightgbm as lgb