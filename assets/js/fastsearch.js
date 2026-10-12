import * as params from '@params';
const input = document.getElementById('searchInput');
const list = document.getElementById('searchResults');
const status = document.getElementById('searchStatus');
let index = [];
let fuse;
const normalize = value => String(value || '').toLocaleLowerCase().normalize('NFKC');
function search() {
  const query = normalize(input.value.trim());
  list.replaceChildren();
  if (!query) { status.textContent = `共 ${index.length} 篇文章，输入关键词开始搜索。`; return; }
  const tokens = query.split(/\s+/).filter(Boolean);
  const exact = index.filter(item => tokens.every(token => normalize(`${item.title} ${item.summary} ${item.content}`).includes(token)));
  const results = exact.length ? exact : fuse.search(query, {limit:30}).map(result => result.item);
  status.textContent = results.length ? `找到 ${results.length} 篇相关文章` : `没有找到“${input.value.trim()}”，试试更短的关键词。`;
  for (const item of results.slice(0,30)) {
    const li = document.createElement('li');
    const a = document.createElement('a');
    a.className = 'entry-link'; a.href = item.permalink;
    const heading = document.createElement('h2'); heading.textContent = item.title;
    const p = document.createElement('p'); p.textContent = item.summary || String(item.content).slice(0,100);
    a.append(heading,p); li.append(a); list.append(li);
  }
}
async function init() {
  try {
    const response = await fetch('../index.json');
    if (!response.ok) throw new Error('Search index unavailable');
    index = await response.json();
    fuse = new Fuse(index, {keys:['title','summary','content'],ignoreLocation:true,threshold:0.25,minMatchCharLength:1});
    input.disabled = false;
    const query = new URLSearchParams(window.location.search).get('q');
    if (query) input.value = query;
    search(); input.focus();
  } catch {
    status.textContent = '文章索引暂时无法读取，请刷新后重试，或从归档浏览。';
  }
}
input.addEventListener('input', search);
input.addEventListener('search', search);
input.addEventListener('keydown', event => {
  if (event.key === 'Escape') { input.value=''; search(); }
  if (event.key === 'ArrowDown') { event.preventDefault(); list.querySelector('a')?.focus(); }
  if (event.key === 'Enter') list.querySelector('a')?.click();
});
list.addEventListener('keydown', event => {
  const links = [...list.querySelectorAll('a')];
  const i = links.indexOf(document.activeElement);
  if (event.key === 'ArrowDown') { event.preventDefault(); links[Math.min(i+1,links.length-1)]?.focus(); }
  if (event.key === 'ArrowUp') { event.preventDefault(); (i <= 0 ? input : links[i-1]).focus(); }
  if (event.key === 'Escape') input.focus();
});
init();
