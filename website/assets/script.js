/* ============================================================
   GUM Landing Page - Interactive Scripts
   ============================================================ */

// ============================================================
// i18n - Language Translations
// ============================================================

const translations = {
    en: {
        'nav.features': 'Features',
        'nav.install': 'Install',
        'nav.docs': 'Docs',
        'nav.github': 'GitHub',

        'hero.badge': 'v1.1.0 — Now with arrow-key menus',
        'hero.title.1': 'Switch Git identities',
        'hero.title.2': 'in one command.',
        'hero.subtitle': 'GUM is a tiny CLI that manages multiple Git accounts, SSH keys, and configs — like nvm, but for your Git identities.',
        'hero.cta.primary': 'Get Started',
        'hero.cta.secondary': 'Star on GitHub',
        'hero.install': 'or install via',

        'pain.title': 'The daily pain',
        'pain.subtitle': 'Every developer with multiple Git accounts knows this dance.',
        'pain.before.title': 'Without gum',
        'pain.before.1': '# Switching to work account...',
        'pain.before.2': 'git config --global user.name "zhangsan"',
        'pain.before.3': 'git config --global user.email "zhangsan@corp.com"',
        'pain.before.4': '# Edit ~/.ssh/config manually...',
        'pain.before.5': 'ssh-add ~/.ssh/work_key',
        'pain.before.6': '# 😤 Repeat every. single. day.',
        'pain.after.title': 'With gum',
        'pain.after.1': '# Morning',
        'pain.after.2': 'gum use work',
        'pain.after.3': '✓ Switched to work',
        'pain.after.4': '# Evening',
        'pain.after.5': 'gum use home',
        'pain.after.6': '✓ Switched to home',

        'features.title': 'Everything you need',
        'features.subtitle': 'Built for developers who care about their workflow.',
        'features.1.title': 'One-command switching',
        'features.1.desc': 'gum use work or gum use home — all your Git config and SSH keys swap instantly.',
        'features.2.title': 'Smart SSH detection',
        'features.2.desc': 'Auto-reads your existing ~/.ssh/config so you don\'t have to retype anything.',
        'features.3.title': 'Auto key generation',
        'features.3.desc': 'Generates ed25519 SSH keys for new identities. Public key shown for instant copy-paste.',
        'features.4.title': 'Non-destructive',
        'features.4.desc': 'Your existing SSH config is never touched. gum manages its blocks via marker comments.',
        'features.5.title': 'Per-repo override',
        'features.5.desc': 'Use a different identity for a single repo with --local. Global stays untouched.',
        'features.6.title': 'Interactive UI',
        'features.6.desc': 'Arrow keys, vim bindings (j/k), or numbers — choose your preferred input style.',

        'install.title': 'Install in seconds',
        'install.subtitle': 'Pick your platform.',

        'demo.title': 'See it in action',
        'demo.subtitle': 'A complete workflow, zero friction.',

        'why.title': 'Why gum?',
        'why.subtitle': 'A focused tool that does one thing extremely well.',
        'why.1.title': 'Zero dependencies',
        'why.1.desc': 'Pure Bash. No Node, no Python, no compiled binary. Works everywhere bash works.',
        'why.2.title': '< 50KB',
        'why.2.desc': 'A single file. You can read every line in 20 minutes.',
        'why.3.title': 'Open source',
        'why.3.desc': 'MIT licensed. No telemetry, no analytics, no surprises.',

        'cta.title': 'Ready to stop the dance?',
        'cta.subtitle': 'Install gum in 5 seconds and never type git config --global again.',

        'footer.tagline': 'Switch Git identities in one command.',
        'footer.product': 'Product',
        'footer.community': 'Community',
        'footer.docs': 'Documentation',
        'footer.changelog': 'Changelog',
        'footer.contributing': 'Contributing',
        'footer.issues': 'Issues',
        'footer.discussions': 'Discussions',
        'footer.architecture': 'Architecture',
        'footer.license': 'Released under MIT License',
    },
    zh: {
        'nav.features': '特性',
        'nav.install': '安装',
        'nav.docs': '文档',
        'nav.github': 'GitHub',

        'hero.badge': 'v1.1.0 — 现已支持方向键选择',
        'hero.title.1': '一条命令切换',
        'hero.title.2': 'Git 身份。',
        'hero.subtitle': 'GUM 是一个轻量级 CLI 工具，统一管理多个 Git 账号、SSH 密钥和配置 — 类似 nvm，但是用于 Git 身份切换。',
        'hero.cta.primary': '开始使用',
        'hero.cta.secondary': '在 GitHub 标星',
        'hero.install': '或通过包管理器安装',

        'pain.title': '每天都在重复的痛苦',
        'pain.subtitle': '每个有多个 Git 账号的开发者都懂这个流程。',
        'pain.before.title': '没有 gum',
        'pain.before.1': '# 切换到工作账号...',
        'pain.before.2': 'git config --global user.name "zhangsan"',
        'pain.before.3': 'git config --global user.email "zhangsan@corp.com"',
        'pain.before.4': '# 手动改 ~/.ssh/config...',
        'pain.before.5': 'ssh-add ~/.ssh/work_key',
        'pain.before.6': '# 😤 每。天。重。复。',
        'pain.after.title': '有了 gum',
        'pain.after.1': '# 早上上班',
        'pain.after.2': 'gum use work',
        'pain.after.3': '✓ 已切换到 work',
        'pain.after.4': '# 下班回家',
        'pain.after.5': 'gum use home',
        'pain.after.6': '✓ 已切换到 home',

        'features.title': '你需要的全部功能',
        'features.subtitle': '为重视工作流的开发者打造。',
        'features.1.title': '一键切换',
        'features.1.desc': 'gum use work 或 gum use home — Git 配置和 SSH 密钥瞬间同步切换。',
        'features.2.title': '智能 SSH 检测',
        'features.2.desc': '自动读取已有的 ~/.ssh/config，无需手动重新输入任何配置。',
        'features.3.title': '自动生成密钥',
        'features.3.desc': '为新身份自动生成 ed25519 SSH 密钥。公钥直接展示，方便复制添加。',
        'features.4.title': '非侵入式',
        'features.4.desc': '完全不影响你已有的 SSH 配置。gum 通过标记注释管理自己的配置块。',
        'features.5.title': '单仓库覆盖',
        'features.5.desc': '使用 --local 为某个仓库独立设置身份。全局配置保持不变。',
        'features.6.title': '交互式 UI',
        'features.6.desc': '方向键、vim 风格 (j/k)、或直接输入数字 — 选你喜欢的方式。',

        'install.title': '秒级安装',
        'install.subtitle': '选择你的平台。',

        'demo.title': '看它实际运行',
        'demo.subtitle': '完整流程，零摩擦。',

        'why.title': '为什么选择 gum？',
        'why.subtitle': '一个把一件事做到极致的专注工具。',
        'why.1.title': '零依赖',
        'why.1.desc': '纯 Bash 实现。不需要 Node、Python 或编译二进制。bash 能跑的地方它都能跑。',
        'why.2.title': '< 50KB',
        'why.2.desc': '单文件。20 分钟你就能读完每一行代码。',
        'why.3.title': '开源透明',
        'why.3.desc': 'MIT 协议。无遥测、无埋点、无惊喜。',

        'cta.title': '不想再重复操作了？',
        'cta.subtitle': '5 秒安装 gum，从此告别 git config --global。',

        'footer.tagline': '一条命令切换 Git 身份。',
        'footer.product': '产品',
        'footer.community': '社区',
        'footer.docs': '文档',
        'footer.changelog': '更新日志',
        'footer.contributing': '贡献指南',
        'footer.issues': 'Issues',
        'footer.discussions': '讨论',
        'footer.architecture': '架构说明',
        'footer.license': '基于 MIT 协议发布',
    }
};

let currentLang = localStorage.getItem('gum-lang') || (navigator.language.startsWith('zh') ? 'zh' : 'en');

function setLanguage(lang) {
    currentLang = lang;
    localStorage.setItem('gum-lang', lang);

    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.dataset.i18n;
        if (translations[lang][key]) {
            el.textContent = translations[lang][key];
        }
    });

    document.documentElement.lang = lang;

    // Update language toggle UI
    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.lang === lang);
    });
}

// ============================================================
// Hero Terminal Animation
// ============================================================

const heroSequence = [
    { text: '$ gum use work', class: 'term-cmd', delay: 30 },
    { text: '\n', delay: 200 },
    { text: '✓ Switched to \'work\' (global)', class: 'term-success', delay: 20 },
    { text: '\n  ', delay: 100 },
    { text: 'user.name  = zhangsan', class: 'term-dim', delay: 15 },
    { text: '\n  ', delay: 100 },
    { text: 'user.email = zhangsan@corp.com', class: 'term-dim', delay: 15 },
    { text: '\n  ', delay: 100 },
    { text: 'ssh.key    = ~/.ssh/id_rsa_work', class: 'term-dim', delay: 15 },
    { text: '\n\n', delay: 600 },
    { text: '$ git commit -m "ship it 🚀"', class: 'term-cmd', delay: 30 },
    { text: '\n', delay: 200 },
    { text: '[main 7a3b2c1] ship it 🚀', class: 'term-out', delay: 20 },
    { text: '\n\n', delay: 800 },
    { text: '$ gum use home', class: 'term-cmd', delay: 30 },
    { text: '\n', delay: 200 },
    { text: '✓ Switched to \'home\' (global)', class: 'term-success', delay: 20 },
    { text: '\n  ', delay: 100 },
    { text: 'user.name  = ziyi', class: 'term-dim', delay: 15 },
    { text: '\n  ', delay: 100 },
    { text: 'user.email = ziyi@163.com', class: 'term-dim', delay: 15 },
    { text: '\n\n', delay: 800 },
    { text: '$ ', class: 'term-cmd', delay: 30 },
];

async function typeText(target, text, className, delay) {
    const span = document.createElement('span');
    if (className) span.className = className;
    target.appendChild(span);

    for (const char of text) {
        span.textContent += char;
        await sleep(delay);
    }
}

function sleep(ms) {
    return new Promise(r => setTimeout(r, ms));
}

async function runHeroTerminal() {
    const target = document.getElementById('hero-terminal-content');
    if (!target) return;

    while (true) {
        target.innerHTML = '<span class="cursor"></span>';

        for (const part of heroSequence) {
            const cursor = target.querySelector('.cursor');
            if (cursor) cursor.remove();
            await typeText(target, part.text, part.class, part.delay || 25);
            target.appendChild(createCursor());
        }

        // Pause then loop
        await sleep(3000);
    }
}

function createCursor() {
    const c = document.createElement('span');
    c.className = 'cursor';
    return c;
}

// ============================================================
// Install Tabs
// ============================================================

function initInstallTabs() {
    const tabs = document.querySelectorAll('.install-tab');
    const contents = document.querySelectorAll('.install-content');

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const target = tab.dataset.target;
            tabs.forEach(t => t.classList.toggle('active', t === tab));
            contents.forEach(c => c.classList.toggle('active', c.id === target));
        });
    });
}

// ============================================================
// Copy Buttons
// ============================================================

function initCopyButtons() {
    document.querySelectorAll('.copy-btn').forEach(btn => {
        btn.addEventListener('click', async () => {
            const target = btn.parentElement.querySelector('.code-text');
            if (!target) return;

            const text = target.textContent;
            try {
                await navigator.clipboard.writeText(text);
                const orig = btn.textContent;
                btn.textContent = '✓ Copied';
                btn.classList.add('copied');
                setTimeout(() => {
                    btn.textContent = orig;
                    btn.classList.remove('copied');
                }, 2000);
            } catch (e) {
                console.error('Copy failed:', e);
            }
        });
    });
}

// ============================================================
// Language Toggle
// ============================================================

function initLanguageToggle() {
    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            setLanguage(btn.dataset.lang);
        });
    });
}

// ============================================================
// Smooth scroll for nav links
// ============================================================

function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(link => {
        link.addEventListener('click', e => {
            const targetId = link.getAttribute('href');
            if (targetId === '#') return;
            const target = document.querySelector(targetId);
            if (target) {
                e.preventDefault();
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        });
    });
}

// ============================================================
// Init
// ============================================================

document.addEventListener('DOMContentLoaded', () => {
    setLanguage(currentLang);
    initInstallTabs();
    initCopyButtons();
    initLanguageToggle();
    initSmoothScroll();
    runHeroTerminal();
});
