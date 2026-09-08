let allBooks = [];
let folderStructure = {};
let currentPath = 'libraria/';

// Matrix Rain Effect
function initMatrix() {
  const canvas = document.getElementById('matrix-canvas');
  const ctx = canvas.getContext('2d');
  
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  
  const chars = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF';
  const charArray = chars.split('');
  const fontSize = 14;
  const columns = canvas.width / fontSize;
  const drops = [];
  
  for (let i = 0; i < columns; i++) {
    drops[i] = Math.random() * -100;
  }
  
  function draw() {
    ctx.fillStyle = 'rgba(0, 8, 8, 0.05)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    ctx.fillStyle = '#00ffff';
    ctx.font = fontSize + 'px monospace';
    
    for (let i = 0; i < drops.length; i++) {
      const text = charArray[Math.floor(Math.random() * charArray.length)];
      ctx.fillStyle = `rgba(0, 255, 255, ${Math.random() * 0.5 + 0.1})`;
      ctx.fillText(text, i * fontSize, drops[i] * fontSize);
      
      if (drops[i] * fontSize > canvas.height && Math.random() > 0.975) {
        drops[i] = 0;
      }
      drops[i]++;
    }
  }
  
  setInterval(draw, 50);
  
  window.addEventListener('resize', () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  });
}

async function loadExplorer() {
  try {
    initMatrix();
    const response = await fetch('data/data_books.json');
    allBooks = await response.json();
    buildFolderStructure();
    renderFolderTree();
    renderFolderContents(currentPath);
  } catch (error) {
    console.error('Erro ao carregar explorador:', error);
    document.getElementById('folder-tree').innerHTML = '<p style="color: #00ffff;">[ ERRO AO CARREGAR SISTEMA ]</p>';
  }
}

function buildFolderStructure() {
  folderStructure = {};
  
  allBooks.forEach(book => {
    const parts = book.path.split('/');
    let current = folderStructure;
    
    for (let i = 0; i < parts.length - 1; i++) {
      const part = parts[i];
      if (!current[part]) {
        current[part] = { _children: {}, _books: [] };
      }
      current = current[part]._children;
    }
  });
}

function renderFolderTree() {
  const treeEl = document.getElementById('folder-tree');
  treeEl.innerHTML = buildTreeHTML(folderStructure, 'libraria');
  
  treeEl.addEventListener('click', (e) => {
    const folderEl = e.target.closest('.tree-folder');
    if (!folderEl) return;
    
    const path = folderEl.dataset.path;
    
    if (e.target.classList.contains('tree-toggle')) {
      folderEl.classList.toggle('expanded');
    } else {
      currentPath = path;
      updatePathDisplay(path);
      renderFolderContents(path);
      
      document.querySelectorAll('.tree-folder').forEach(f => f.classList.remove('active'));
      folderEl.classList.add('active');
    }
  });
}

function buildTreeHTML(structure, basePath) {
  let html = '';
  const sortedKeys = Object.keys(structure).sort();
  
  sortedKeys.forEach(key => {
    const fullPath = basePath + '/' + key;
    const hasChildren = Object.keys(structure[key]._children).length > 0;
    const bookCount = countBooksInFolder(structure[key]);
    
    html += `
      <div class="tree-folder" data-path="${fullPath}">
        <span class="tree-toggle">${hasChildren ? '▶' : ' '}</span>
        <span class="tree-icon">📁</span>
        <span class="tree-name">${key}</span>
        <span class="tree-count">(${bookCount})</span>
        <div class="tree-children">
          ${hasChildren ? buildTreeHTML(structure[key]._children, fullPath) : ''}
        </div>
      </div>
    `;
  });
  
  return html;
}

function countBooksInFolder(folder) {
  let count = folder._books ? folder._books.length : 0;
  Object.values(folder._children).forEach(child => {
    count += countBooksInFolder(child);
  });
  return count;
}

function updatePathDisplay(path) {
  const pathEl = document.getElementById('current-path');
  pathEl.innerHTML = `
    <span class="path-label">CAMINHO:</span>
    <span class="path-value">${path}/</span>
  `;
}

function renderFolderContents(path) {
  const contentsEl = document.getElementById('folder-contents');
  
  const booksInFolder = allBooks.filter(book => {
    const bookDir = book.path.substring(0, book.path.lastIndexOf('/'));
    return bookDir === path;
  });
  
  const subDirs = new Set();
  allBooks.forEach(book => {
    const parts = book.path.split('/');
    if (parts.length > 2) {
      const bookBasePath = parts.slice(0, -1).join('/');
      if (bookBasePath.startsWith(path) && bookBasePath !== path) {
        const relativePath = bookBasePath.substring(path.length + 1);
        const firstDir = relativePath.split('/')[0];
        if (firstDir) {
          subDirs.add(firstDir);
        }
      }
    }
  });
  
  let html = '';
  
  if (subDirs.size > 0) {
    html += '<div class="contents-section">';
    html += '<div class="contents-section-title">PASTAS</div>';
    [...subDirs].sort().forEach(dir => {
      const fullPath = path + '/' + dir;
      html += `
        <div class="contents-folder" data-path="${fullPath}">
          <span class="contents-folder-icon">📁</span>
          <span class="contents-folder-name">${dir}</span>
        </div>
      `;
    });
    html += '</div>';
  }
  
  if (booksInFolder.length > 0) {
    html += '<div class="contents-section">';
    html += `<div class="contents-section-title">LIVROS (${booksInFolder.length})</div>`;
    booksInFolder.forEach(book => {
      const title = book.title_clean || book.name || 'Sem titulo';
      const ext = book.name.split('.').pop().toUpperCase();
      html += `
        <a href="book.html?path=${encodeURIComponent(book.path)}" class="contents-book">
          <span class="contents-book-icon">📄</span>
          <span class="contents-book-info">
            <span class="contents-book-title">${title}</span>
            <span class="contents-book-ext">${ext}</span>
          </span>
        </a>
      `;
    });
    html += '</div>';
  }
  
  if (booksInFolder.length === 0 && subDirs.size === 0) {
    html = '<p style="color: #00cccc; text-align: center; padding: 20px;">[ PASTA VAZIA ]</p>';
  }
  
  contentsEl.innerHTML = html;
  
  contentsEl.querySelectorAll('.contents-folder').forEach(folder => {
    folder.addEventListener('click', () => {
      const path = folder.dataset.path;
      currentPath = path;
      updatePathDisplay(path);
      renderFolderContents(path);
      
      const treeNode = document.querySelector(`.tree-folder[data-path="${path}"]`);
      if (treeNode) {
        document.querySelectorAll('.tree-folder').forEach(f => f.classList.remove('active'));
        treeNode.classList.add('active');
        
        let parent = treeNode.parentElement;
        while (parent) {
          if (parent.classList && parent.classList.contains('tree-folder')) {
            parent.classList.add('expanded');
          }
          parent = parent.parentElement;
        }
      }
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-expand-all').addEventListener('click', () => {
    const folders = document.querySelectorAll('.tree-folder');
    const allExpanded = [...folders].every(f => f.classList.contains('expanded'));
    
    folders.forEach(f => {
      if (allExpanded) {
        f.classList.remove('expanded');
      } else {
        f.classList.add('expanded');
      }
    });
    
    document.getElementById('btn-expand-all').textContent = allExpanded ? 'EXPANDIR TUDO' : 'RECOLHER TUDO';
  });
});

loadExplorer();
