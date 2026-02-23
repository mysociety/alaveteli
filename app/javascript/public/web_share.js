// We are using <a> instead of <button> because the button won't be inheriting 
// the color property from the themes.
document.querySelectorAll('.js-share-request').forEach(function(element) {
  element.addEventListener('click', handleShare);
  element.addEventListener('keydown', handleShare);
});

function handleShare(e) {
  // Keyboard navigation it behaves like a button
  if (e.type === 'keydown' && e.key !== 'Enter' && e.key !== ' ') {
    return;
  }

  // Prevent the anchor behaviour even if the navigator does not support web sharing
  e.preventDefault();

  // Prevent page scroll
  if (e.type === 'keydown' && e.key === ' ') {
    e.preventDefault();
  }

  if (navigator.canShare) {
    e.stopImmediatePropagation();

    navigator.share({
      title: this.dataset.shareTitle,
      url: this.dataset.shareUrl
    })
  }
}
