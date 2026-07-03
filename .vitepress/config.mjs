import { defineConfig } from 'vitepress'

export default defineConfig({
  lang: 'zh-CN',
  title: 'BG9JOI',
  description: 'lzdogbro 的个人主页 — 少儿编程教师 · 业余无线电爱好者',

  head: [
    ['link', { rel: 'icon', href: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y=".9em" font-size="90">📻</text></svg>' }],
    ['script', {}, `(function(){var h=new Date().getHours();document.documentElement.classList.toggle('dark',h<6||h>=18);var D='sun-theme-date',T='vitepress-theme-appearance',t=new Date().toDateString();if(localStorage.getItem(D)!==t){fetch('https://ipapi.co/json/').then(function(r){return r.json()}).then(function(g){return fetch('https://api.sunrise-sunset.org/json?lat='+g.latitude+'&lng='+g.longitude+'&formatted=0').then(function(r){return r.json()})}).then(function(s){var n=new Date(),r=new Date(s.results.sunrise),u=new Date(s.results.sunset),d=n<r||n>u;document.documentElement.classList.toggle('dark',d);localStorage.setItem(T,d?'dark':'light');localStorage.setItem(D,t)}).catch(function(){localStorage.setItem(T,h<6||h>=18?'dark':'light');localStorage.setItem(D,t)})}})();`],
  ],

  themeConfig: {
    nav: [
      { text: '关于我', link: '/about' },
      { text: '业余无线电', link: '/radio' },
      { text: '关于乡愁', link: '/food' },
      { text: 'JXXOJ', link: '/jxxoj' },
      { text: '打字游戏', link: '/typegame' },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/lzdogbro' },
    ],

    footer: {
      message: 'MIT Licensed | Copyright © 2026 lzdogbro',
    },
  },
})
