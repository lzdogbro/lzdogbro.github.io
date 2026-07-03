export const redirects = JSON.parse("{}")

export const routes = Object.fromEntries([
  ["/", { loader: () => import(/* webpackChunkName: "index.html" */"/Users/dog/Code/devlop/lzdogbro.github.io/docs/README.md"), meta: {"title":""} }],
  ["/404.html", { loader: () => import(/* webpackChunkName: "404.html" */"/Users/dog/Code/devlop/lzdogbro.github.io/docs/.vuepress/.temp/pages/404.html.vue"), meta: {"title":""} }],
]);
