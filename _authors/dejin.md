---
short_name: dejin
name: Dejintime
position: 算法学习者
avatar: /assets/images/touxiang.jpg
github: dejintime
email: dejintime@example.com
bio: 一个致力于学习记录算法的小白
---

<div class="author-profile">
  <div class="author-header">
    <div class="author-avatar">
      {% if page.avatar %}
        <img src="{{ page.avatar }}" alt="{{ page.name }}">
      {% else %}
        <div class="avatar-placeholder">{{ page.name | slice: 0, 1 }}</div>
      {% endif %}
    </div>
    <div class="author-info">
      <h1>{{ page.name }}</h1>
      <p class="author-position">{{ page.position }}</p>
      <p class="author-bio">{{ page.bio }}</p>
    </div>
  </div>

  <div class="author-social">
    {% if page.github %}
      <a href="https://github.com/{{ page.github }}" target="_blank" class="social-link">
        <i class="fab fa-github"></i> GitHub
      </a>
    {% endif %}
    {% if page.email %}
      <a href="mailto:{{ page.email }}" class="social-link">
        <i class="fas fa-envelope"></i> Email
      </a>
    {% endif %}
  </div>

  <div class="author-stats">
    <div class="stat-item">
      <span class="stat-value">{{ site.posts | where: "author", page.short_name | size }}</span>
      <span class="stat-label">文章</span>
    </div>
    <div class="stat-item">
      <span class="stat-value">{{ site.categories | size }}</span>
      <span class="stat-label">分类</span>
    </div>
  </div>

  <div class="author-posts">
    <h2>TA的文章</h2>
    <ul class="simple-post-list">
      {% assign author_posts = site.posts | where: "author", page.short_name %}
      {% for post in author_posts %}
        <li><a href="{{ post.url }}">{{ post.title }}</a></li>
      {% endfor %}
    </ul>
  </div>
</div>

<style>
.author-profile {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

.author-header {
  display: flex;
  align-items: center;
  gap: 2rem;
  margin-bottom: 2rem;
}

.author-avatar {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.author-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-placeholder {
  width: 100%;
  height: 100%;
  background: #3498db;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 3rem;
  font-weight: bold;
}

.author-info h1 {
  margin: 0 0 0.5rem 0;
  font-size: 2rem;
  color: #2c3e50;
}

.author-position {
  color: #666;
  font-size: 1.1rem;
  margin: 0 0 1rem 0;
}

.author-bio {
  color: #666;
  line-height: 1.6;
}

.author-social {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
}

.social-link {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: #f5f7fa;
  border-radius: 2rem;
  color: #666;
  text-decoration: none;
  transition: all 0.3s ease;
}

.social-link:hover {
  background: #3498db;
  color: white;
}

.author-stats {
  display: flex;
  gap: 2rem;
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: #f5f7fa;
  border-radius: 1rem;
}

.stat-item {
  text-align: center;
}

.stat-value {
  display: block;
  font-size: 1.5rem;
  font-weight: bold;
  color: #2c3e50;
}

.stat-label {
  color: #666;
  font-size: 0.9rem;
}

.author-posts h2 {
  margin-bottom: 1.5rem;
  color: #2c3e50;
}

/* 新增：简单文章列表样式 */
.simple-post-list {
  list-style: none;
  padding-left: 0;
  margin-top: 1rem; /* 与标题的间距 */
}

.simple-post-list li {
  padding: 0.75rem 0.25rem; /* 上下留白，左右稍微留白 */
  border-bottom: 1px solid #e9ecef; /* 更柔和的分割线 */
  transition: background-color 0.2s ease-in-out;
}

.simple-post-list li:last-child {
  border-bottom: none; /* 最后一个列表项没有下边框 */
}

.simple-post-list li a {
  text-decoration: none;
  color: #343a40; /* 深色文字，易于阅读 */
  font-size: 1.1rem; /* 合适的标题字号 */
  font-weight: 500; /* 中等字重 */
  transition: color 0.2s ease-in-out;
}

.simple-post-list li a:hover {
  color: #007bff; /* 鼠标悬停时变为主题蓝色 */
  text-decoration: underline;
}

@media (max-width: 768px) {
  .author-header {
    flex-direction: column;
    text-align: center;
  }
  
  .author-social {
    justify-content: center;
  }
  
  .author-stats {
    flex-direction: column;
    gap: 1rem;
  }
}
</style>

<!-- 添加 Font Awesome 图标库 -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">