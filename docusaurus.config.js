const {themes: prismThemes} = require('prism-react-renderer');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'StarDataParadise',
  tagline: 'Ürünü tanıyın, SQL öğrenin, uygulamanızı geliştirin.',
  favicon: 'img/favicon.svg',
  url: 'https://paradiseincdevelopers.github.io',
  baseUrl: '/StarDataParadise-Docs/',
  organizationName: 'ParadiseIncDevelopers',
  projectName: 'StarDataParadise-Docs',
  deploymentBranch: 'gh-pages',
  trailingSlash: true,
  onBrokenLinks: 'throw',
  i18n: {defaultLocale: 'tr', locales: ['tr']},
  markdown: {
    mermaid: true,
    hooks: {onBrokenMarkdownLinks: 'throw', onBrokenMarkdownImages: 'throw'},
  },
  presets: [['classic', {
    docs: {
      sidebarPath: require.resolve('./sidebars.js'),
      routeBasePath: '/',
      numberPrefixParser: false,
      editUrl: 'https://github.com/ParadiseIncDevelopers/StarDataParadise-Docs/edit/main/',
    },
    blog: false,
    theme: {customCss: require.resolve('./src/css/custom.css')},
  }]],
  themes: [
    '@docusaurus/theme-mermaid',
    [require.resolve('@easyops-cn/docusaurus-search-local'), {
      hashed: 'filename', language: ['tr', 'en'],
      indexDocs: true, indexBlog: false, docsRouteBasePath: '/',
      highlightSearchTermsOnTargetPage: true,
      explicitSearchResultPath: true,
      searchResultLimits: 8,
    }],
  ],
  themeConfig: {
    colorMode: {defaultMode: 'dark', respectPrefersColorScheme: true},
    navbar: {
      title: 'StarDataParadise',
      logo: {alt: 'SDP', src: 'img/logo.svg'},
      items: [
        {type: 'docSidebar', sidebarId: 'tutorialSidebar', label: 'Dokümantasyon', position: 'left'},
        {label: 'SDK’lar', position: 'left', items: [
          {label: 'Node.js', to: '/sdk/nodejs/01-kurulum/'},
          {label: 'Python', to: '/sdk/python/01-kurulum/'},
          {label: 'Java', to: '/sdk/java/kurulum/'},
          {label: '.NET / .NET Framework', to: '/sdk/dotnet/kurulum/'},
          {label: 'C / C++', to: '/sdk/c-cpp/01-kurulum/'},
        ]},
        {label: 'GitHub', href: 'https://github.com/ParadiseIncDevelopers/StarDataParadise-Docs', position: 'right'},
      ],
    },
    footer: {style: 'dark', links: [
      {title: 'Öğrenin', items: [
        {label: 'StarDataParadise nedir?', to: '/baslangic/stardataparadise-nedir/'},
        {label: 'SQL öğrenme yolu', to: '/sql/'},
        {label: 'Veritabanı ve tablolar', to: '/veritabani/'},
      ]},
      {title: 'Geliştirin', items: [
        {label: 'SDK rehberleri', to: '/sdk/'},
        {label: 'Örnek projeler', to: '/ornekler/'},
        {label: 'AI ve Knowledge', to: '/ai/temeller/'},
      ]},
      {title: 'Kaynaklar', items: [
        {label: 'Sürüm ve yetenek kapsamı', to: '/referans/surum-uyumluluk/'},
        {label: 'Dokümantasyon deposu', href: 'https://github.com/ParadiseIncDevelopers/StarDataParadise-Docs'},
        {label: 'Siteyi güncelleme', to: '/referans/yayinlama/'},
      ]},
    ], copyright: 'Copyright © 2026 Paradise Bilişim'},
    prism: {
      theme: prismThemes.github, darkTheme: prismThemes.dracula,
      additionalLanguages: ['sql','java','csharp','python','powershell','bash','json','c','cpp','cmake','gradle'],
    },
    mermaid: {theme: {light: 'default', dark: 'dark'}},
    tableOfContents: {minHeadingLevel: 2, maxHeadingLevel: 3},
  },
};
module.exports = config;
