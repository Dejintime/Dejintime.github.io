---
layout: post
title: "Transformer"
date: 2026-05-05
categories: DeepLearning
tags: blog
---

>**摘要**：本文系统梳理了 Transformer 的核心架构原理，按自底向上的顺序展开：从 Self-Attention 的数学机制出发，依次解析 Multi-Head Attention、Masked Attention 与 Cross Attention 三类注意力变体；随后介绍 Feed Forward Network 与残差-归一化结构的设计动机；最后结合 Encoder-Decoder 框架，对比训练（Teacher Forcing 并行化）与推理（自回归串行生成）两种模式下的数据流，阐明各组件如何协同完成序列到序列的建模任务。

---
# Transformer Architecture
 Transformer 架构图细节如下 
<img class="img-medium" src="{{ '/assets/images/transformer.png' | relative_url }}" alt="Transformer 架构" />
# 1. Self-Attention

自注意力机制是 Transformer 的核心，它允许模型在处理每个词时，动态地关注输入序列中的所有其他词，从而捕获全局依赖关系。对于一个句子中的每个词，自注意力会计算它与句中所有词（包括自己）的**相关性分数**，然后用这些分数对所有词的表征做加权求和，得到该词的**上下文感知表征**。

设输入序列长度为 $n$，每个词的 embedding 维度为 $d_k$。

1. **生成 Q、K、V 矩阵**：对输入矩阵 $X \in \mathbb{R}^{n \times d_k}$，分别乘以三个可学习的权重矩阵 $W^Q, W^K, W^V$，得到 Query、Key、Value：
   $$Q = X W^Q,\quad K = X W^K,\quad V = X W^V$$
2. **计算注意力分数**：通过 Q 和 K 的点积计算每对词之间的相关性：
   $$\text{Scores} = Q K^\top$$
3. **缩放（Scale）**：将分数除以 $\sqrt{d_k}$，防止点积值过大导致 softmax 梯度消失：
   $$\text{Scaled Scores} = \frac{Q K^\top}{\sqrt{d_k}}$$
4. **Softmax 归一化**：对每一行做 softmax，得到注意力权重：
   $$\text{Attention Weights} = \text{softmax}\left(\frac{Q K^\top}{\sqrt{d_k}}\right)$$
5. **加权求和**：用注意力权重对 V 加权求和，得到最终输出：
   $$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{Q K^\top}{\sqrt{d_k}}\right) V$$
# 2. Multi-Head self-Attention

**Multi-Head**并行计算多个注意力头，每个头有自己独立的 $W^Q, W^K, W^V$，从而让模型在不同子空间中捕获不同类型的关系（如语法关系、语义关系、指代关系等）。
**self-attention**是指输入的$QKV$矩阵来自于同一个矩阵$X$,详见[1. Self-Attention](#1-self-attention自注意力机制)

$$\text{MultiHead}(Q, K, V) = \text{Concat}(\text{head}_1, \dots, \text{head}_h) W^O$$

其中$head_i$为$$\text{head}_i = \text{Attention}(Q W_i^Q, K W_i^K, V W_i^V)$$
将每个 head 输出的矩阵 $z_i$（维度 $d_k$）拼接后得到大矩阵 $Z$（维度 $h \times d_k = d_{model}$），再经 $W^{O}$ 线性变换，投影回 $d_{model}$ 空间，融合各头信息
# 3. Multi-Head Masked Attention

在训练阶段，Decoder 在第 $t$ 个时刻需要对 $t$ 之后的 token 做掩码，防止模型捕捉到t之后的序列信息。具体做法：在计算relevance score后、softmax 之前，将未来位置的注意力分数设为 $-\infty$。这样经过 softmax 后，对应权重趋近于 0，等同于完全不关注这些位置，达到掩码效果。

$$\text{MaskedAttention} = \text{softmax}\left(\frac{Q K^\top}{\sqrt{d_k}} + M\right) V$$

其中 $M$ 为 mask 矩阵，未来位置填 $-\infty$，其余填 $0$。
# 4. Multi-Head Cross Attention

Cross Attention是连接Encoder和Decoder的桥梁：
$$Q = H_{\text{dec}} W^Q,\quad K = H_{\text{enc}} W^K,\quad V = H_{\text{enc}} W^V$$
其中$H_{dec}$为Decoder上一层Masked-Attention的输出，$H_{enc}$为Encoder层最后的输出

$$\text{CrossAttn} = \text{softmax}\left(\frac{Q K^\top}{\sqrt{d_k}}\right) V$$
其中 $Q$ 来自 Decoder Masked-Attention 层输出，表示当前时刻要生成的 token 的 query；$K, V$ 来自 Encoder 最终层输出，为 Decoder 注入源序列的全局语义信息。

Multi-Head 形式：

$$\text{MultiHead}_{\text{cross}} = \text{Concat}(\text{head}_1, \dots, \text{head}_h) W^O$$

$$\text{head}_i = \text{Attention}(H_{\text{dec}} W_i^Q,\; H_{\text{enc}} W_i^K,\; H_{\text{enc}} W_i^V)$$

# 5. Feed Forward Network（前馈网络）

每个注意力子层后面接一个全连接前馈网络，对每个位置独立地做两次线性变换（中间有激活函数）：

$$\text{FFN}(x) = \max(0, x W_1 + b_1) W_2 + b_2$$

现代变体常用 GELU、SiLU（Swish）等激活函数代替 ReLU，并在中间维度会扩展（如从 512 扩展到 2048，再压回 512），近似于"记忆存储 + 检索"的过程。

# 6. Add & Norm（残差连接与层归一化）

每个子层（Attention 和 FFN）都使用残差连接和层归一化：

$$\text{output} = \text{LayerNorm}(x + \text{Sublayer}(x))$$
### Post-Norm vs Pre-Norm

- **Post-Norm（原始论文）**：$\text{LayerNorm}(x + \text{Sublayer}(x))$ —— 容易训练不稳定，需要 warm-up
- **Pre-Norm（现代主流）**：$x + \text{Sublayer}(\text{LayerNorm}(x))$ —— 训练更稳定，绝大多数现代 LLM（GPT、LLaMA 等）使用
# 7. Positional Encoding（位置编码）

Attention 本身对位置不敏感——打乱输入序列，输出只会跟着打乱。为了让模型感知词的顺序，Transformer 给输入 embedding 加上位置编码。
### 使用不同频率的正弦/余弦函数：

$$PE_{(pos, 2i)} = \sin\left(\frac{pos}{10000^{2i / d_{model}}}\right)$$

$$PE_{(pos, 2i+1)} = \cos\left(\frac{pos}{10000^{2i / d_{model}}}\right)$$

优点：可以外推到训练时未见过的序列长度；相对位置信息可通过三角恒等式推导。

# 8. 工作流过程

## 8.1 训练阶段

### Encoder

Encoder 通过 Multi-Head Self-Attention 对源序列进行**双向上下文建模**——每个 token 均可无遮挡地关注序列内所有位置，捕获全局依赖关系。经 $N$ 层堆叠编码，输出表征 $H_{\text{enc}}$ 已融合完整的上下文语义与句法特征。

此后 Encoder 即退出计算图，其输出的 Key、Value 矩阵（由 $H_{\text{enc}}$ 经 $W^K, W^V$ 投影得到）作为**静态上下文缓存**，供 Decoder 在所有后续时间步中复用。

### Decoder

训练阶段采用 **Teacher Forcing** 策略：将目标序列整体右移一位（shifted right），一次性并行输入 Decoder。

1. **Masked Multi-Head Self-Attention**：通过 mask 矩阵施加因果约束，使位置 $t$ 仅关注 $[1, t]$，屏蔽 $t+1$ 及之后的位置。该层输出 Query 向量，其语义可理解为"在当前已生成的前缀条件下，模型期望从源序列中检索何种信息"。
2. **Multi-Head Cross-Attention**：以 Masked-Attention 产出的 $Q_{\text{dec}}$ 作为 Query，Encoder 缓存提供的 $K_{\text{enc}}, V_{\text{enc}}$ 作为 Key 和 Value，执行源序列与目标序列的信息对齐。
3. **Feed Forward + Add & Norm**：对 Cross-Attention 输出做非线性变换与残差连接，最终经 Linear + Softmax 得到词表概率分布。

由于训练时目标序列完全已知，整个 Decoder 的 $T$ 个时间步可**并行前向计算**，一次性得到所有位置的预测概率分布，然后通过交叉熵损失反向传播更新参数。

## 8.2 推理阶段

### Encoder

推理时 Encoder 的运行方式与训练完全一致——输入完整源序列，一次性前向计算，最终输出 $K_{\text{enc}}, V_{\text{enc}}$ 作为静态上下文供 Decoder 反复检索，期间不再参与任何计算。

### Decoder

推理阶段转为**自回归生成**（autoregressive generation），无法并行：

1. 初始时刻仅输入起始符 `<BOS>`，Decoder 执行一次前向计算，预测第 1 个 token。
2. 将该 token 拼接入已生成序列末尾，作为下一时刻的输入，循环执行，直至预测出结束符 `<EOS>` 或达到最大长度。
3. 每一步中，Masked Self-Attention 仅关注已生成的前缀部分（因果一致性），Cross-Attention 则以当前步生成的 Query 从 Encoder 缓存的 $K_{\text{enc}}, V_{\text{enc}}$ 中检索源序列语义。

> **常见误区**：推理时 Masked Self-Attention 并非"等同于普通 self-attention"。其仍然施加因果 mask（只能看到已生成前缀），只是因为已生成序列本身不含未来信息，直观上与"看到全部"效果相似，但机制上始终遵循自回归约束。
