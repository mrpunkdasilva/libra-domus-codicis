let books = [];
let categories = new Set();
let currentPage = 1;
let filteredBooks = [];
const booksPerPage = 10;

// Show skeleton loading
function showSkeletons() {
  const statsEl = document.getElementById('stats');
  const booksEl = document.getElementById('books');
  
  statsEl.innerHTML = `
    <div class="skeleton-stats">
      <div class="skeleton-stat">
        <div class="skeleton-stat-number skeleton"></div>
        <div class="skeleton-stat-label skeleton"></div>
      </div>
      <div class="skeleton-stat">
        <div class="skeleton-stat-number skeleton"></div>
        <div class="skeleton-stat-label skeleton"></div>
      </div>
    </div>
  `;
  
  let skeletons = '';
  for (let i = 0; i < 10; i++) {
    skeletons += `
      <div class="skeleton-card">
        <div class="skeleton-cover skeleton"></div>
        <div class="skeleton-content">
          <div class="skeleton-category skeleton"></div>
          <div class="skeleton-title skeleton"></div>
        </div>
      </div>
    `;
  }
  booksEl.innerHTML = skeletons;
}

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

async function loadBooks() {
  try {
    showSkeletons();
    initMatrix();
    const response = await fetch('data/data_books.json');
    books = await response.json();
    extractCategories();
    renderStats();
    renderCategories();
    renderBooks(books);
    animateCounter();
  } catch (error) {
    console.error('Erro ao carregar livros:', error);
    document.getElementById('books').innerHTML = '<p style="color: #00ffff; text-align: center;">[ ERRO AO CARREGAR SISTEMA ]</p>';
  }
}

function extractCategories() {
  books.forEach(book => {
    const category = book.category || '';
    if (category) {
      categories.add(category);
    }
  });
}

function renderStats() {
  const statsEl = document.getElementById('stats');
  statsEl.innerHTML = `
    <div class="stat">
      <div class="stat-number">${books.length}</div>
      <div class="stat-label">LIVROS</div>
    </div>
    <div class="stat">
      <div class="stat-number">${categories.size}</div>
      <div class="stat-label">CATEGORIAS</div>
    </div>
  `;
}

function renderCategories() {
  const categoriesEl = document.getElementById('categories');
  const sorted = [...categories].sort();
  
  categoriesEl.innerHTML = '<button class="category-btn active" data-category="all">TODOS</button>';
  
  sorted.forEach(cat => {
    const btn = document.createElement('button');
    btn.className = 'category-btn';
    btn.dataset.category = cat;
    btn.textContent = cat.split('/').pop().toUpperCase();
    categoriesEl.appendChild(btn);
  });

  categoriesEl.addEventListener('click', (e) => {
    if (e.target.classList.contains('category-btn')) {
      document.querySelectorAll('.category-btn').forEach(b => b.classList.remove('active'));
      e.target.classList.add('active');
      
      currentPage = 1;
      const category = e.target.dataset.category;
      if (category === 'all') {
        renderBooks(books);
      } else {
        renderBooks(books.filter(b => b.category === category));
      }
    }
  });
}

function renderBooks(list) {
  const booksEl = document.getElementById('books');
  filteredBooks = list;
  
  const totalPages = Math.ceil(list.length / booksPerPage);
  if (currentPage > totalPages) {
    currentPage = totalPages || 1;
  }
  
  if (list.length === 0) {
    booksEl.innerHTML = '<p style="color: #00ffff; text-align: center;">[ NENHUM REGISTRO ENCONTRADO ]</p>';
    document.getElementById('webring').style.display = 'none';
    return;
  }

  const startIndex = (currentPage - 1) * booksPerPage;
  const endIndex = startIndex + booksPerPage;
  const paginatedBooks = list.slice(startIndex, endIndex);

  booksEl.innerHTML = paginatedBooks.map(book => {
    const category = book.category || 'Sem categoria';
    const title = book.title_clean || book.name || 'Sem titulo';
    const path = book.path || '#';

    return `
      <a href="book.html?path=${encodeURIComponent(path)}" class="book-card" style="text-decoration: none; color: inherit;">
        <img src="images/book-cover.svg" alt="Capa" class="book-cover"/>
        <div class="book-overlay">
          <div class="book-category">${category}</div>
          <div class="book-title">${title}</div>
        </div>
      </a>
    `;
  }).join('');

  updateWebring();
}

function updateWebring() {
  const webring = document.getElementById('webring');
  const totalPages = Math.ceil(filteredBooks.length / booksPerPage);

  if (totalPages <= 1) {
    webring.style.display = 'none';
    return;
  }

  webring.style.display = '';
}

function animateCounter() {
  const counterEl = document.getElementById('counter');
  let count = 1337;
  setInterval(() => {
    count++;
    counterEl.textContent = count.toString().padStart(6, '0');
  }, 5000);
}

document.getElementById('search').addEventListener('input', (e) => {
  const query = e.target.value.toLowerCase();
  currentPage = 1;
  if (!query) {
    renderBooks(books);
    return;
  }
  
  const filtered = books.filter(book => {
    const title = (book.title_clean || '').toLowerCase();
    const desc = (book.description || '').toLowerCase();
    const name = (book.name || '').toLowerCase();
    return title.includes(query) || desc.includes(query) || name.includes(query);
  });
  
  renderBooks(filtered);
});

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-prev').addEventListener('click', (e) => {
    e.preventDefault();
    if (currentPage > 1) {
      currentPage--;
      renderBooks(filteredBooks);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  });

  document.getElementById('btn-next').addEventListener('click', (e) => {
    e.preventDefault();
    const totalPages = Math.ceil(filteredBooks.length / booksPerPage);
    if (currentPage < totalPages) {
      currentPage++;
      renderBooks(filteredBooks);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  });

  document.getElementById('btn-random').addEventListener('click', (e) => {
    e.preventDefault();
    const totalPages = Math.ceil(filteredBooks.length / booksPerPage);
    if (totalPages > 1) {
      currentPage = Math.floor(Math.random() * totalPages) + 1;
    } else {
      currentPage = 1;
    }
    renderBooks(filteredBooks);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
});

loadBooks();
