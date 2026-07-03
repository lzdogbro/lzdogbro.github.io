import { viteBundler } from '@vuepress/bundler-vite'
import { defaultTheme } from '@vuepress/theme-default'

export default {
  lang: 'zh-CN',
  title: 'lzdogbro',
  description: '这是我的个人主页',

  bundler: viteBundler(),
  theme: defaultTheme({
    navbar: [
      { text: '首页', link: '/' },
      { text: 'GitHub', link: 'https://github.com/lzdogbro' },
    ],
    sidebar: false,
  }),
}
