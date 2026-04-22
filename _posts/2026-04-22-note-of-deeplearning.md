---
layout: post
title: "从零实现线性回归和SoftMax"
date: 2026-04-22
categories: DeepLearning
tags: blog
---

> 本文手动实现了线性回归和SoftMax函数，分析了SGD的运算过程，实现了SGD的训练代码并且兼容官方的SGD代码

---
## 1. 从零实现线性回归

### 核心目标
用 PyTorch 的张量 + autograd（自动求导），手写“数据生成 → 小批量迭代 → 模型 → 损失 → SGD → 训练循环”，学会线性回归训练的最小闭环。

### 关键代码骨架

**1）合成数据（已知真参数）**
- 思路：先用 $y = Xw + b$ 生成标签，再加高斯噪声，便于验证训练能否学回 $w,b$。

```python
def synthetic_data(w, b, num_examples):
    X = torch.normal(0, 1, (num_examples, len(w)))
    y = torch.matmul(X, w) + b
    y += torch.normal(0, 0.01, y.shape)
    return X, y.reshape((-1, 1))

true_w = torch.tensor([2, -3.4])
true_b = 4.2
features, labels = synthetic_data(true_w, true_b, 1000)
```

**2）小批量数据迭代器（打乱 + yield）**
- 思路：自己实现 mini-batch SGD 所需的数据流。

```python
def data_iter(batch_size, features, labels):
    num_examples = len(features)
    indices = list(range(num_examples))
    random.shuffle(indices)
    for i in range(0, num_examples, batch_size):
        batch_indices = torch.tensor(indices[i: min(i + batch_size, num_examples)])
        yield features[batch_indices], labels[batch_indices]
```

**3）模型、损失、优化器（全部从零手写）**
- 线性模型：$\hat{y} = Xw + b$。
- 平方损失：$\ell(\hat{y}, y) = \frac{(\hat{y}-y)^2}{2}$（写成 $\frac{1}{2}$ 是为了求导更干净）。
- SGD 更新：$\theta \leftarrow \theta - \eta \frac{\nabla\theta}{\text{batch\_size}}$。

```python
w = torch.normal(0, 0.01, size=(2, 1), requires_grad=True)
b = torch.zeros(1, requires_grad=True)

def linreg(X, w, b):
    return torch.matmul(X, w) + b

def squared_loss(y_hat, y):
    return (y_hat - y.reshape(y_hat.shape))**2 / 2

def sgd(params, lr, batch_size):
    with torch.no_grad():
        for param in params:
            param -= lr * param.grad / batch_size
            param.grad.zero_()
```

**4）训练循环（forward → loss → backward → step）**
- 你实现的训练闭环非常标准：
  1. 前向计算 $\hat{y}$
  2. 计算每样本损失 $\ell$
  3. `l.sum().backward()` 得到梯度
  4. `sgd` 手动更新参数

```python
for epoch in range(num_epochs):
    for X, y in data_iter(batch_size, features, labels):
        l = loss(net(X, w, b), y)
        l.sum().backward()
        sgd([w, b], lr, batch_size)
```

---

## 2. Softmax 从零开始实现

### 核心目标
把线性回归从“回归”扩展到“多分类”：
- 线性层输出 logits
- 用 softmax 把 logits 变成概率
- 用交叉熵做损失
- 写出准确率评估与完整训练循环（含可视化）

### 关键代码骨架

**1）参数与 softmax**
```python
num_inputs = 784
num_outputs = 10
W = torch.normal(0, 0.01, size=(num_inputs, num_outputs), requires_grad=True)
b = torch.zeros(num_outputs, requires_grad=True)

def softmax(X):
    X_exp = torch.exp(X)
    partition = X_exp.sum(1, keepdim=True)
    return X_exp / partition
```

**原理**：对每个样本 $x$，
$$
\mathrm{softmax}(z)_k = \frac{e^{z_k}}{\sum_j e^{z_j}}
$$
输出是一个概率分布（各类概率和为 1）。

> 提醒：你这里的 softmax 没做数值稳定（常见做法是 `X = X - X.max(dim=1, keepdim=True).values` 再 exp），当 logits 很大时可能溢出。

**2）模型（flatten + 线性 + softmax）**
```python
def net(X):
    return softmax(torch.matmul(X.reshape(-1, W.shape[0]), W) + b)
```

**3）交叉熵损失（手写版）**[[交叉熵损失函数]]
```python
def cross_entropy(y_hat, y):
    return -torch.log(y_hat[range(len(y_hat)), y])
```

**原理**：对单样本，交叉熵等价于“取真实类别的预测概率并取负对数”：
$$
\ell = -\log \hat{y}_{y}
$$
预测越自信且正确（$\hat{y}_{y}$ 越接近 1），损失越小。


**4）评估与训练（兼容两种 updater）**
- 如果 `updater` 是 `torch.optim.Optimizer`，就走标准 `zero_grad/backward/step`
- 否则就走自己写的 `d2l.sgd`

```python
def train_epoch_ch3(net, train_iter, loss, updater):
    if isinstance(net, torch.nn.Module):
        net.train()
    metric = Accumulator(3)
    for X, y in train_iter:
        y_hat = net(X)
        l = loss(y_hat, y)
        if isinstance(updater, torch.optim.Optimizer):
            updater.zero_grad()
            l.mean().backward()
            updater.step()
            metric.add(float(l) * len(y), accuracy(y_hat, y), y.numel())
        else:
            l.sum().backward()
            updater(X.shape[0])
            metric.add(float(l.sum()), accuracy(y_hat, y), y.numel())
    return metric[0] / metric[2], metric[1] / metric[2]
lr = 0.1
def updater(batch_size):
    return d2l.sgd([W, b], lr, batch_size)
```

---

## 3. Softmax 简洁实现（高层 API）

### 核心目标
用 `torch.nn` 的模块化方式快速搭出 softmax 回归，并用内置损失/优化器训练。

### 关键代码骨架

**1）模型：Flatten + Linear**
```python
net = nn.Sequential(nn.Flatten(), nn.Linear(784, 10))

def init_weights(m):
    if type(m) == nn.Linear:
        nn.init.normal_(m.weight, std=0.01)

net.apply(init_weights)
```

**2）损失与优化器**
```python
loss = nn.CrossEntropyLoss()
trainer = torch.optim.SGD(net.parameters(), lr=0.1)
```

**原理点**：`nn.CrossEntropyLoss()` 在实现上等价于 `log_softmax + NLLLoss`，因此你这里的 `net` **不需要**显式写 softmax。

**3）训练入口**
```python
num_epochs = 10
train_ch3(net, train_iter, test_iter, loss, num_epochs, trainer)
```

> 注意：这个 notebook 里直接调用了 `train_ch3`，但它的定义来自你在 3.4 里写的训练框架（或你在同一运行环境里提前执行过的定义）。如果你单独运行 3.5，需要先确保 `train_ch3` 已经在当前 kernel 里。
