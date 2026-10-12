(() => {
  const host = document.getElementById('giscus-container');
  const status = document.getElementById('comment-status');
  if (!host || !status) return;
  const theme = () => document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light';
  const fallback = () => {
    status.hidden = false;
    status.replaceChildren(document.createTextNode('评论暂时未能加载。你可以刷新页面，或前往 '));
    const link = document.createElement('a');
    link.href = `https://github.com/${host.dataset.repo}/discussions`;
    link.textContent = 'GitHub Discussions';
    status.append(link, document.createTextNode(' 交流。'));
  };
  const timer = window.setTimeout(fallback, 18000);
  window.addEventListener('message', event => {
    if (event.origin !== 'https://giscus.app' || event.source !== host.querySelector('iframe')?.contentWindow || !event.data?.giscus) return;
    if (event.data.giscus.error) {
      window.clearTimeout(timer);
      fallback();
    } else if (event.data.giscus.resizeHeight) {
      window.clearTimeout(timer);
      status.hidden = true;
    }
  });
  const script = document.createElement('script');
  script.src = 'https://giscus.app/client.js';
  script.async = true;
  script.crossOrigin = 'anonymous';
  const attrs = {repo:host.dataset.repo,'repo-id':host.dataset.repoId,category:host.dataset.category,'category-id':host.dataset.categoryId,mapping:'pathname',strict:'1','reactions-enabled':'1','emit-metadata':'0','input-position':'top',theme:theme(),lang:'zh-CN',loading:'eager'};
  for (const [key,value] of Object.entries(attrs)) script.setAttribute(`data-${key}`, value);
  script.onerror = () => { window.clearTimeout(timer); fallback(); };
  host.append(script);
  new MutationObserver(() => host.querySelector('iframe')?.contentWindow.postMessage({giscus:{setConfig:{theme:theme()}}}, 'https://giscus.app')).observe(document.documentElement, {attributes:true,attributeFilter:['data-theme']});
})();
