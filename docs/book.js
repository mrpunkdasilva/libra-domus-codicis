let books = [];
let currentBook = null;

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

async function loadBookDetails() {
  try {
    initMatrix();
    
    const params = new URLSearchParams(window.location.search);
    const bookPath = params.get('path');
    
    if (!bookPath) {
      document.getElementById('book-details').innerHTML = '<p style="color: #00ffff; text-align: center;">[ LIVRO NAO ENCONTRADO ]</p>';
      return;
    }
    
    const response = await fetch('data/data_books.json');
    books = await response.json();
    
    currentBook = books.find(b => b.path === bookPath);
    
    if (!currentBook) {
      document.getElementById('book-details').innerHTML = '<p style="color: #00ffff; text-align: center;">[ LIVRO NAO ENCONTRADO ]</p>';
      return;
    }
    
    renderBookDetails(currentBook);
    renderRecommendations(currentBook);
    
  } catch (error) {
    console.error('Erro ao carregar livro:', error);
    document.getElementById('book-details').innerHTML = '<p style="color: #00ffff; text-align: center;">[ ERRO AO CARREGAR SISTEMA ]</p>';
  }
}

function renderBookDetails(book) {
  const detailsEl = document.getElementById('book-details');
  const githubBase = 'https://github.com/mrpunkdasilva/libra-domus-codicis/blob/main/';
  const githubUrl = githubBase + book.path;
  
  detailsEl.innerHTML = `
    <div class="book-details-cover">
      <img src="images/book-cover.svg" alt="Capa"/>
    </div>
    <div class="book-details-info">
      <div class="book-details-category">${book.category || 'Sem categoria'}</div>
      <div class="book-details-title">${book.title_clean || book.name || 'Sem titulo'}</div>
      <a href="${githubUrl}" target="_blank" class="book-details-link">ABRIR LIVRO</a>
    </div>
  `;
}

function renderRecommendations(book) {
  const listEl = document.getElementById('recommendations-list');
  
  // Algoritmo de recomendacao probabilistico e estatistico
  const scores = books
    .filter(b => b.path !== book.path)
    .map(b => {
      let score = 0;
      
      // 1. Similaridade de categoria (peso: 0.4)
      if (b.category === book.category) {
        score += 0.4;
      }
      
      // 2. Similaridade de palavras no titulo (peso: 0.3)
      const bookWords = (book.title_clean || '').toLowerCase().split(/\s+/);
      const recWords = (b.title_clean || '').toLowerCase().split(/\s+/);
      const commonWords = bookWords.filter(w => recWords.includes(w) && w.length > 3);
      score += (commonWords.length / Math.max(bookWords.length, 1)) * 0.3;
      
      // 3. Distribuicao de probabilidade por categoria (peso: 0.2)
      const categoryCount = books.filter(x => x.category === b.category).length;
      const categoryProb = categoryCount / books.length;
      score += categoryProb * 0.2;
      
      // 4. Aleatoriedade ponderada (peso: 0.1)
      score += Math.random() * 0.1;
      
      // 5. Bonus por ser da mesma sub-categoria
      const bookSubCat = book.category ? book.category.split('/').pop() : '';
      const recSubCat = b.category ? b.category.split('/').pop() : '';
      if (bookSubCat === recSubCat && bookSubCat !== '') {
        score += 0.15;
      }
      
      return { book: b, score: score };
    });
  
  // Ordena por score e pega top 5
  const recommendations = scores
    .sort((a, b) => b.score - a.score)
    .slice(0, 5)
    .map(item => item.book);
  
  if (recommendations.length === 0) {
    listEl.innerHTML = '<p style="color: #00cccc;">[ NENHUMA RECOMENDACAO ENCONTRADA ]</p>';
    return;
  }
  
  listEl.innerHTML = recommendations.map(rec => {
    return `
      <a href="book.html?path=${encodeURIComponent(rec.path)}" class="book-card" style="text-decoration: none; color: inherit;">
        <img src="images/book-cover.svg" alt="Capa" class="book-cover"/>
        <div class="book-overlay">
          <div class="book-category">${rec.category || ''}</div>
          <div class="book-title">${rec.title_clean || rec.name || ''}</div>
        </div>
      </a>
    `;
  }).join('');
}

loadBookDetails();
