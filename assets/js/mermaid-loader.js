mermaid.initialize({
  startOnLoad: false,
  securityLevel: 'strict',
  theme: 'base',
  themeVariables: {
    primaryColor: '#eaf0e3',
    primaryTextColor: '#24382f',
    primaryBorderColor: '#88a27c',
    lineColor: '#73876c',
    fontFamily: 'Microsoft Yahei,system-ui,sans-serif',
    fontSize: '15px'
  },
  flowchart: { htmlLabels: false, curve: 'linear' }
});
mermaid.run({ querySelector: '.mermaid' }).catch((error) => {
  console.error('Unable to render article diagrams', error);
});
