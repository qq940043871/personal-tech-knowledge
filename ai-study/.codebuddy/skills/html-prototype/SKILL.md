---
name: html-prototype
description: Generate high-fidelity HTML+Tailwind CSS prototypes for enterprise management systems. Use this when the user asks to create new pages, extend the prototype, build a similar management system, or generate HTML mockups for any enterprise application module.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# HTML Prototype Framework Skill

You are an expert at building high-fidelity static HTML prototypes using Tailwind CSS (CDN) and Font Awesome (CDN). This skill captures the proven patterns from a Contract Management System prototype so you can reproduce them for new pages, modules, or entirely new enterprise management systems.

## Core Rules

1. **Zero build tools** — No package.json, no bundler, no npm. Everything loads from CDN.
2. **Chinese-first** — Always use `lang="zh-CN"`, Chinese labels and content.
3. **Static mock data** — All data is hardcoded in HTML. No API calls, no data files.
4. **Self-contained pages** — Every `.html` file is an independent, fully renderable page.
5. **iframe shell model** — `index.html` acts as the shell with sidebar nav and an `<iframe>` content area.
6. **Paired documentation** — Every `.html` page should have a same-named `.md` file explaining requirements and structure.

---

## Project Shell: index.html

The shell uses this structure:
- **Top header** (`h-16`): System logo/title on the left, user avatar/name/notifications on the right
- **Left sidebar** (`w-64`, `sticky top-16`): Navigation groups with section headers and nav items with icons
- **Main area** (`flex-1`): Contains `<iframe id="mainFrame">` that loads pages via `src` changes
- **Navigation**: `onclick="loadPage('path/to/page.html')"` sets iframe src and toggles `.active-nav` class

### Shell Template (index.html)

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>系统名称</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: '#3B82F6',
                        secondary: '#64748B',
                        accent: '#10B981'
                    }
                }
            }
        }
    </script>
    <style>
        html, body { height: 100%; margin: 0; padding: 0; overflow: hidden; }
        .portal-container { height: calc(100vh - 64px); overflow: hidden; }
        .nav-item:hover { background-color: #EFF6FF; }
        .active-nav { background-color: #DBEAFE; border-left: 4px solid #3B82F6; }
        #mainFrame { width: 100%; height: 100%; border: 0; overflow: hidden; }
    </style>
</head>
<body class="bg-gray-50">
    <!-- Header -->
    <header class="bg-white shadow-sm h-16 flex items-center px-6">
        <div class="flex items-center">
            <i class="fas fa-icon-name text-primary text-2xl mr-3"></i>
            <h1 class="text-xl font-bold text-gray-800">系统名称</h1>
        </div>
        <div class="ml-auto flex items-center space-x-4">
            <button class="text-gray-600 hover:text-gray-900"><i class="fas fa-bell"></i></button>
            <div class="flex items-center">
                <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white mr-2">
                    <i class="fas fa-user"></i>
                </div>
                <span class="text-gray-700">用户名</span>
            </div>
        </div>
    </header>

    <div class="flex">
        <!-- Sidebar -->
        <aside class="w-64 bg-white shadow-md h-screen sticky top-16">
            <nav class="py-4">
                <div class="px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wider">分组名称</div>
                <a href="#" onclick="loadPage('module/page.html')" class="nav-item active-nav flex items-center px-4 py-3 text-gray-700">
                    <i class="fas fa-home mr-3"></i><span>菜单项</span>
                </a>
                <!-- More nav items... -->
            </nav>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-6 portal-container">
            <iframe id="mainFrame" src="default-page.html" class="w-full h-full border-0 rounded-lg shadow"></iframe>
        </main>
    </div>

    <script>
        function loadPage(page) {
            document.getElementById('mainFrame').src = page;
            document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active-nav'));
            event.currentTarget.classList.add('active-nav');
        }
    </script>
</body>
</html>
```

---

## Page Boilerplate

Every sub-page follows this exact structure:

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>页面标题</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Optional: Chart.js -->
    <!-- <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script> -->
    <!-- Optional: Tailwind config override -->
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: '#3B82F6',
                        secondary: '#64748B',
                        accent: '#10B981'
                    }
                }
            }
        }
    </script>
    <!-- Optional: Custom CSS -->
    <style>
        /* Page-specific styles */
    </style>
</head>
<body class="bg-gray-50">
    <div class="p-6">
        <!-- Page content -->
    </div>

    <script>
        // Page-specific JavaScript
    </script>
</body>
</html>
```

---

## Page Type Patterns

### Type 1: List/CRUD Page (e.g., contract-list, appeal)

The most common pattern. Has: page title bar, stats cards, filter bar, data table, pagination.

**Section order:**
1. **Page title bar** — `flex justify-between items-center mb-6` with h1 title + description, plus action buttons (筛选, 导出, 新建)
2. **Stats cards** — `grid grid-cols-1 md:grid-cols-4 gap-6` with icon circle + label + number
3. **Filter bar** — `bg-white rounded-lg shadow p-4` with `grid grid-cols-1 md:grid-cols-4 gap-4` inputs
4. **Data table** — `bg-white rounded-lg shadow overflow-hidden` with `min-w-full divide-y divide-gray-200`
5. **Pagination** — inside table card footer, `flex items-center justify-between border-t px-4 py-3`

**Stats card pattern:**
```html
<div class="bg-white rounded-lg shadow p-6">
    <div class="flex items-center">
        <div class="p-3 rounded-full bg-blue-100 text-blue-600">
            <i class="fas fa-icon text-xl"></i>
        </div>
        <div class="ml-4">
            <p class="text-gray-500 text-sm">标签</p>
            <h3 class="text-2xl font-bold">1,248</h3>
        </div>
    </div>
</div>
```

**Status badge colors:**
| Status | Badge classes |
|--------|--------------|
| 履约中/合规/正常/完成 | `bg-green-100 text-green-800` |
| 待履约/待处理 | `bg-yellow-100 text-yellow-800` |
| 已作废/不合规/驳回 | `bg-red-100 text-red-800` |
| 已归档/已解决 | `bg-gray-100 text-gray-800` |
| 待复核 | `bg-yellow-100 text-yellow-800` |

**Badge markup:**
```html
<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">状态文本</span>
```

**Filter bar pattern:**
```html
<div class="bg-white rounded-lg shadow mb-6 p-4">
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">字段名</label>
            <input type="text" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="请输入...">
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">状态下拉</label>
            <select class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="">全部状态</option>
                <option value="opt1">选项1</option>
            </select>
        </div>
        <div class="flex items-end">
            <button class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">搜索</button>
        </div>
    </div>
</div>
```

**Table pattern:**
```html
<div class="bg-white rounded-lg shadow overflow-hidden">
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">列名</th>
                    <!-- More columns... -->
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
                </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
                <tr class="hover:bg-gray-50">
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">数据</td>
                    <!-- More cells... -->
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <a href="#" class="text-blue-600 hover:text-blue-900 mr-3">查看</a>
                        <a href="#" class="text-green-600 hover:text-green-900 mr-3">编辑</a>
                        <a href="#" class="text-red-600 hover:text-red-900">删除</a>
                    </td>
                </tr>
                <!-- Repeat for more rows -->
            </tbody>
        </table>
    </div>
    <!-- Pagination -->
    <div class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
        <div class="text-sm text-gray-700">显示第 <span class="font-medium">1</span> 到 <span class="font-medium">10</span> 条，共 <span class="font-medium">97</span> 条记录</div>
        <div>
            <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                <a href="#" class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                    <i class="fas fa-chevron-left"></i>
                </a>
                <a href="#" class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-blue-50 text-sm font-medium text-blue-600">1</a>
                <a href="#" class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50">2</a>
                <a href="#" class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50">3</a>
                <a href="#" class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                    <i class="fas fa-chevron-right"></i>
                </a>
            </nav>
        </div>
    </div>
</div>
```

### Type 2: Dashboard/Portal Page (e.g., admin-portal)

Has: greeting section, stats cards row, chart section (2/3 + 1/3 split), quick actions grid.

**Key sections:**
1. **Greeting** — h1 + date/description
2. **Stats cards** — `grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6` with trend arrows
3. **Chart + recent activity** — `grid grid-cols-1 lg:grid-cols-3 gap-6` with chart (col-span-2) + activity list
4. **Quick actions** — `grid grid-cols-2 md:grid-cols-4 gap-4` icon buttons

**Chart container pattern:**
```html
<div class="bg-white rounded-lg shadow p-6">
    <div class="flex justify-between items-center mb-6">
        <h2 class="text-lg font-bold text-gray-800">图表标题</h2>
        <div class="flex space-x-2">
            <button class="px-3 py-1 text-sm bg-blue-100 text-blue-600 rounded">月度</button>
            <button class="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded">季度</button>
        </div>
    </div>
    <div class="h-64 pt-8 border-t">
        <canvas id="myChart"></canvas>
    </div>
</div>
```

**When using Chart.js**, load it and use this pattern:
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
<script>
    const ctx = document.getElementById('myChart').getContext('2d');
    new Chart(ctx, {
        type: 'line',
        data: {
            labels: ['1月', '2月', '3月', '4月', '5月', '6月'],
            datasets: [{ /* data */ }]
        },
        options: { responsive: true, maintainAspectRatio: false }
    });
</script>
```

### Type 3: Process/Wizard Page (e.g., payment, delivery)

Has: progress stepper, key metric cards, detailed info sections, action buttons.

**Progress stepper:**
```html
<div class="relative mb-8">
    <div class="absolute top-1/2 left-0 right-0 h-0.5 bg-neutral-200 -translate-y-1/2 z-0"></div>
    <div class="absolute top-1/2 left-0 w-2/5 h-0.5 bg-primary -translate-y-1/2 z-10"></div>
    <div class="flex justify-between relative z-20">
        <div class="flex flex-col items-center">
            <div class="w-8 h-8 rounded-full border-2 step-completed flex items-center justify-center mb-2">
                <i class="fa fa-check text-sm"></i>
            </div>
            <span class="text-xs font-medium">已完成步骤</span>
        </div>
        <div class="flex flex-col items-center">
            <div class="w-8 h-8 rounded-full border-2 step-active flex items-center justify-center mb-2">
                <i class="fa fa-icon text-sm"></i>
            </div>
            <span class="text-xs font-medium text-primary">当前步骤</span>
        </div>
        <div class="flex flex-col items-center">
            <div class="w-8 h-8 rounded-full border-2 border-neutral-200 text-neutral-400 flex items-center justify-center mb-2">
                <i class="fa fa-icon text-sm"></i>
            </div>
            <span class="text-xs font-medium text-neutral-500">待处理</span>
        </div>
    </div>
</div>
```

**Stepper CSS classes:**
```css
.step-active { @apply bg-primary text-white border-primary; }
.step-completed { @apply bg-success text-white border-success; }
```

### Type 4: Settings/Config Page (e.g., system-settings)

Has: split layout with left tab navigation and right content panel.

**Tab switching pattern:**
```html
<div class="flex flex-col md:flex-row gap-6">
    <!-- Left tabs -->
    <div class="md:w-1/4">
        <div class="bg-white rounded-lg shadow">
            <div class="p-4 border-b"><h2>设置分类</h2></div>
            <nav class="p-2">
                <a href="#" class="flex items-center px-4 py-3 text-blue-600 bg-blue-50 rounded-lg mb-1" data-target="tab1">
                    <i class="fas fa-icon mr-3"></i><span>标签1</span>
                </a>
                <a href="#" class="flex items-center px-4 py-3 text-gray-700 hover:bg-gray-50 rounded-lg mb-1" data-target="tab2">
                    <i class="fas fa-icon mr-3"></i><span>标签2</span>
                </a>
            </nav>
        </div>
    </div>
    <!-- Right content panels -->
    <div class="md:w-3/4">
        <div class="bg-white rounded-lg shadow settings-content" id="tab1-content">
            <!-- Panel content with table and inline form -->
        </div>
        <div class="bg-white rounded-lg shadow settings-content" id="tab2-content" style="display: none;">
            <!-- Panel content -->
        </div>
    </div>
</div>
<script>
    document.querySelectorAll('#settings-nav .nav-item').forEach(item => {
        item.addEventListener('click', function(e) {
            e.preventDefault();
            document.querySelectorAll('#settings-nav .nav-item').forEach(nav => nav.classList.remove('active', 'text-blue-600', 'bg-blue-50'));
            this.classList.add('active', 'text-blue-600', 'bg-blue-50');
            document.querySelectorAll('.settings-content').forEach(content => content.style.display = 'none');
            const targetId = this.getAttribute('data-target') + '-content';
            document.getElementById(targetId).style.display = 'block';
        });
    });
</script>
```

### Type 5: Big Screen/Dashboard (e.g., admin-screen)

Dark background (`bg-dark-xxx`), glowing cards, animated numbers, map charts. Uses Chart.js geo extensions, lighter font, and tighter grid.

---

## Color Conventions

**Default palette (utility-first pages):**
| Role | Tailwind Class | Hex |
|------|---------------|-----|
| Primary buttons/links | `bg-blue-600`, `text-blue-600` | #2563EB |
| Primary light bg | `bg-blue-100`, `text-blue-600` | - |
| Success badges | `bg-green-100`, `text-green-800` | - |
| Warning badges | `bg-yellow-100`, `text-yellow-800` | - |
| Danger badges | `bg-red-100`, `text-red-800` | - |
| Neutral badges | `bg-gray-100`, `text-gray-800` | - |

**Extended palette (custom config pages):**
```js
tailwind.config = {
    theme: {
        extend: {
            colors: {
                primary: '#165DFF',
                success: '#00B42A',
                warning: '#FF7D00',
                danger: '#F53F3F',
                neutral: {
                    100: '#F2F3F5', 200: '#E5E6EB', 300: '#C9CDD4',
                    400: '#86909C', 500: '#4E5969', 600: '#1D2129',
                }
            }
        }
    }
}
```

---

## Module Directory Structure

Each module gets its own directory:
```
project/
├── index.html              # Shell with sidebar + iframe
├── portal/                 # Dashboard/overview pages
├── module-name/            # Feature module
│   ├── list.html           # List page
│   ├── detail.html         # Detail view
│   ├── form.html           # Form page
│   ├── list.md             # Requirements doc (paired with list.html)
│   └── detail.md           # Requirements doc
├── common/                 # Shared cross-module pages
├── system/                 # Configuration/admin pages
├── report/                 # Report/chart pages
└── screen/                 # Big screen/displays
```

---

## Documentation (.md) Pattern

Every HTML page should have a paired `.md` file with this structure:

```markdown
# 页面名称 (filename.html)

## 页面概述
Brief description of what this page does.

## 功能需求
1. Feature 1
   - Detail sub-point
2. Feature 2

## 页面结构
- Section name
  - Component description
  - Sub-component

## 技术实现
- Technology choice and rationale
- Library usage notes
- Data handling approach (static in prototype)
```

---

## Key Dependencies (CDN)

| Library | CDN URL | When to Use |
|---------|---------|-------------|
| Tailwind CSS | `https://cdn.tailwindcss.com` | Always required |
| Font Awesome 6.4 | `https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css` | Always required |
| Chart.js 3.9.1 | `https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js` | Charts/dashboards |

---

## Development Instructions

When generating a new page:
1. Create the `.html` file in the appropriate module directory using the page boilerplate
2. Create a paired `.md` documentation file with the same base name
3. If adding to an existing project shell, add a new navigation item in `index.html` sidebar
4. If creating a new project, build `index.html` as the shell first, then add sub-pages

When generating a new project:
1. Create `index.html` with the shell template, customizing the title, navigation groups, and menu items
2. Create module directories matching the menu structure
3. Build the default landing page (first page loaded in iframe)
4. Build remaining pages one by one, each as self-contained HTML files
5. Each page gets a paired `.md` documentation file
