document.addEventListener('DOMContentLoaded', function() {

  const grid = document.querySelector('.js-gallery-grid');
  const initialCards = parseInt(grid.getAttribute('masonry-initial-cards')) || 20;
  const cardsPerLoad = parseInt(grid.getAttribute('masonry-cards-per-load')) || 10;
  const loadMoreBtn = document.getElementById('load-more');
  if (!grid || !loadMoreBtn) return;

  const allCards = Array.from(grid.querySelectorAll('.gallery-grid--card'));
  let visibleCount = 0;

  allCards.forEach(card => card.classList.add('grid-hidden'));

  const msnry = new Masonry(grid, {
    itemSelector: '.gallery-grid--card:not(.grid-hidden)',
    columnWidth: '.gallery-grid--sizer',
    gutter: '.gallery-grid--gutter-sizer',
    percentPosition: true,
  });

  function showCards(count) {
    const cardsToShow = allCards.slice(visibleCount, visibleCount + count);
    cardsToShow.forEach(card => card.classList.remove('grid-hidden'));
    visibleCount += cardsToShow.length;

    msnry.reloadItems();
    imagesLoaded(grid).on('progress', function() {
      msnry.layout();
    });

    if (visibleCount >= allCards.length) {
      loadMoreBtn.classList.remove('visible');
    } else {
      loadMoreBtn.classList.add('visible');
    }
  }

  showCards(initialCards);

  // Load more on click
  loadMoreBtn.addEventListener('click', function() {
    showCards(cardsPerLoad);
  });

  // Re-layout on lazy-loaded images
  grid.querySelectorAll('img').forEach(img => {
    img.addEventListener('load', () => {
      msnry.layout();
    });
  });
});
