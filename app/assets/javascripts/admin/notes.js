document.addEventListener('DOMContentLoaded', function () {
  var selectElement = document.getElementById('note_style');
  var bodyInput = document.getElementById('bodyInput');
  var richBodyInput = document.getElementById('richBodyInput');

  function updateBodyVisibility() {
    if (selectElement.value === 'original') {
      bodyInput.style.display = 'block';
      richBodyInput.style.display = 'none';
    } else {
      bodyInput.style.display = 'none';
      richBodyInput.style.display = 'block';
    }
  }

  selectElement.addEventListener('change', updateBodyVisibility);

  updateBodyVisibility();
});
