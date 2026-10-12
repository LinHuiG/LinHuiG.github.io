(() => {
  const root = document.documentElement;
  const system = window.matchMedia('(prefers-color-scheme: dark)');
  const key = 'blog-appearance';
  const valid = value => ['auto', 'light', 'dark'].includes(value) ? value : 'auto';
  let preference = 'auto';
  try { preference = valid(localStorage.getItem(key)); } catch {}
  const apply = () => {
    const theme = preference === 'auto' ? (system.matches ? 'dark' : 'light') : preference;
    root.dataset.theme = theme;
    root.dataset.appearance = preference;
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.content = theme === 'dark' ? '#000000' : '#f5f5f7';
    const control = document.getElementById('appearance');
    if (control) control.value = preference;
  };
  apply();
  system.addEventListener('change', () => { if (preference === 'auto') apply(); });
  window.addEventListener('storage', event => {
    if (event.key === key || event.key === null) {
      preference = valid(event.newValue);
      apply();
    }
  });
  document.addEventListener('DOMContentLoaded', () => {
    const control = document.getElementById('appearance');
    if (!control) return;
    control.closest('.appearance-control').hidden = false;
    control.value = preference;
    control.addEventListener('change', () => {
      preference = valid(control.value);
      try { localStorage.setItem(key, preference); } catch {}
      apply();
    });
  });
})();
