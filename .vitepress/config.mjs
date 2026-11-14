import { defineConfig } from 'vitepress'

/**
 * 站点默认语言为中文（站点根目录）。
 * 其它语言放在 /en/ /ja/ /fr/ /ru/ 子目录，文件名与中文页面一一对应。
 */

const LANG_KEY = 'lzdogbro-lang'

// 首次访问按浏览器语言跳转；用户手动切换过语言后不再自动跳转。
const autoLangScript = `(function(){try{
var K='${LANG_KEY}';
var P=/^\\/(en|ja|fr|ru)(?=\\/|$)/;
function get(){try{return localStorage.getItem(K)}catch(e){return null}}
function set(v){try{localStorage.setItem(K,v)}catch(e){}}
var m=location.pathname.match(P),cur=m?m[1]:'zh';
document.addEventListener('click',function(e){
  var t=e.target;
  if(!t||typeof t.closest!=='function')return;
  var a=t.closest('a[href]');
  if(!a)return;
  var h=a.getAttribute('href')||'';
  if(h.charAt(0)!=='/')return;
  var mm=h.match(P);
  set(mm?mm[1]:'zh');
},true);
var want=get();
if(!want){
  var ls=(navigator.languages&&navigator.languages.length)?navigator.languages:[navigator.language||''];
  for(var i=0;i<ls.length;i++){
    var b=String(ls[i]||'').toLowerCase().split('-')[0];
    if(b==='zh'||b==='en'||b==='ja'||b==='fr'||b==='ru'){want=b;break}
  }
  if(!want)want='en';
  set(want);
}
if(want===cur)return;
if(/\\/404\\.html$/.test(location.pathname))return;
var rest=location.pathname.replace(P,'')||'/';
var target=(want==='zh')?rest:((rest==='/')?('/'+want+'/'):('/'+want+rest));
location.replace(target+location.search+location.hash);
}catch(e){}})();`

const head = [
  ['link', { rel: 'icon', href: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y=".9em" font-size="90">📻</text></svg>' }],
  // 按访客 IP 位置日出日落自动切换日/夜模式
  ['script', {}, `(function(){var h=new Date().getHours();document.documentElement.classList.toggle('dark',h<6||h>=18);var D='sun-theme-date',T='vitepress-theme-appearance',t=new Date().toDateString();if(localStorage.getItem(D)!==t){fetch('https://ipapi.co/json/').then(function(r){return r.json()}).then(function(g){return fetch('https://api.sunrise-sunset.org/json?lat='+g.latitude+'&lng='+g.longitude+'&formatted=0').then(function(r){return r.json()})}).then(function(s){var n=new Date(),r=new Date(s.results.sunrise),u=new Date(s.results.sunset),d=n<r||n>u;document.documentElement.classList.toggle('dark',d);localStorage.setItem(T,d?'dark':'light');localStorage.setItem(D,t)}).catch(function(){localStorage.setItem(T,h<6||h>=18?'dark':'light');localStorage.setItem(D,t)})}})();`],
  // 语言自动跳转
  ['script', {}, autoLangScript],
]

const zhNav = [
  { text: '关于我', link: '/about' },
  { text: '业余无线电', link: '/radio' },
  { text: '关于乡愁', link: '/food' },
  { text: 'JXXOJ', link: '/jxxoj' },
  { text: '打字游戏', link: '/typegame' },
]

const enNav = [
  { text: 'About', link: '/en/about' },
  { text: 'Ham Radio', link: '/en/radio' },
  { text: 'Nostalgia', link: '/en/food' },
  { text: 'JXXOJ', link: '/en/jxxoj' },
  { text: 'Typing Game', link: '/en/typegame' },
]

const jaNav = [
  { text: '私について', link: '/ja/about' },
  { text: 'アマチュア無線', link: '/ja/radio' },
  { text: '郷愁', link: '/ja/food' },
  { text: 'JXXOJ', link: '/ja/jxxoj' },
  { text: 'タイピングゲーム', link: '/ja/typegame' },
]

const frNav = [
  { text: 'À propos', link: '/fr/about' },
  { text: 'Radioamateur', link: '/fr/radio' },
  { text: 'Nostalgie', link: '/fr/food' },
  { text: 'JXXOJ', link: '/fr/jxxoj' },
  { text: 'Jeu de dactylographie', link: '/fr/typegame' },
]

const ruNav = [
  { text: 'Обо мне', link: '/ru/about' },
  { text: 'Радиолюбительство', link: '/ru/radio' },
  { text: 'Ностальгия', link: '/ru/food' },
  { text: 'JXXOJ', link: '/ru/jxxoj' },
  { text: 'Игра в наборе текста', link: '/ru/typegame' },
]

const footer = { message: 'MIT Licensed | Copyright © 2026 lzdogbro' }
const socialLinks = [{ icon: 'github', link: 'https://github.com/lzdogbro' }]

export default defineConfig({
  lang: 'zh-CN',
  title: '兰州狗哥',
  description: 'lzdogbro 的个人主页 — 少儿编程教师 · 业余无线电爱好者',

  head,

  themeConfig: {
    nav: zhNav,
    notFound: {
      code: '404',
      title: '页面不存在',
      quote: '你要找的页面可能已经被移动或删除，检查一下地址，或者回首页看看。',
      linkText: '返回首页',
      linkLabel: '返回首页',
    },
    socialLinks,
    footer,
  },

  locales: {
    root: {
      label: '简体中文',
      lang: 'zh-CN',
      themeConfig: { nav: zhNav },
    },
    en: {
      label: 'English',
      lang: 'en-US',
      link: '/en/',
      title: 'Dogbro',
      description: "lzdogbro's personal site — youth programming teacher · amateur radio enthusiast",
      themeConfig: {
        nav: enNav,
        notFound: {
          code: '404',
          title: 'PAGE NOT FOUND',
          quote: "The page you're looking for doesn't exist or has been moved. Check the address, or head back home.",
          linkText: 'Take me home',
          linkLabel: 'Go to home',
        },
      },
    },
    ja: {
      label: '日本語',
      lang: 'ja-JP',
      link: '/ja/',
      title: 'Dogbro',
      description: 'lzdogbro の個人サイト — 子ども向けプログラミング講師・アマチュア無線愛好家',
      themeConfig: {
        nav: jaNav,
        notFound: {
          code: '404',
          title: 'ページが見つかりません',
          quote: 'お探しのページは存在しないか、移動された可能性があります。URL を確認するか、ホームへお戻りください。',
          linkText: 'ホームに戻る',
          linkLabel: 'ホームに戻る',
        },
      },
    },
    fr: {
      label: 'Français',
      lang: 'fr-FR',
      link: '/fr/',
      title: 'Dogbro',
      description: 'Le site personnel de lzdogbro — professeur de programmation pour enfants · radioamateur',
      themeConfig: {
        nav: frNav,
        notFound: {
          code: '404',
          title: 'PAGE INTROUVABLE',
          quote: "La page que vous cherchez n'existe pas ou a été déplacée. Vérifiez l'adresse, ou revenez à l'accueil.",
          linkText: "Retour à l'accueil",
          linkLabel: "Aller à l'accueil",
        },
      },
    },
    ru: {
      label: 'Русский',
      lang: 'ru-RU',
      link: '/ru/',
      title: 'Dogbro',
      description: 'Личный сайт lzdogbro — преподаватель программирования для детей · радиолюбитель',
      themeConfig: {
        nav: ruNav,
        notFound: {
          code: '404',
          title: 'СТРАНИЦА НЕ НАЙДЕНА',
          quote: 'Страница, которую вы ищете, не существует или была перемещена. Проверьте адрес или вернитесь на главную.',
          linkText: 'На главную',
          linkLabel: 'На главную',
        },
      },
    },
  },
})
