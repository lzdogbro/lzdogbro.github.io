import { viteBundler } from '@vuepress/bundler-vite'
import { defaultTheme } from '@vuepress/theme-default'

export default {
  lang: 'zh-CN',
  title: 'BG9JOI',
  description: 'lzdogbro 的个人主页 — 少儿编程教师 · 业余无线电爱好者',

  head: [
    ['link', { rel: 'icon', href: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y=".9em" font-size="90">📻</text></svg>' }],
  ],

  bundler: viteBundler(),
  theme: defaultTheme({
    navbar: [
      { text: '首页', link: '/' },
      { text: 'JXXOJ', link: 'https://oj.jxx.asia' },
      { text: '打字游戏', link: 'https://typegame.jxx.asia' },
      { text: '鲸小小', link: 'https://jxx.asia' },
      { text: 'GitHub', link: 'https://github.com/lzdogbro' },
    ],
    sidebar: false,
  }),
}
