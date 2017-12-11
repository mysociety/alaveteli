(function ($) {
  $('.carousel').each(function () {
    var $carousel = $(this)
    var $content = $('.carousel-content', $carousel)
    var $buttons = $('.carousel-buttons', $carousel)
    var $currentPage = $('.current-page', $carousel)
    var $totalPages = $('.total-pages', $carousel)
    var $nextPageButton = $('button.carousel-button#next', $buttons)
    var $prevPageButton = $('button.carousel-button#prev', $buttons)
    var $dismissItemAnchors = $('a.carousel-item-dismiss', $carousel)

    var items = function () {
      return $('.carousel-item', $content)
    }

    var currentItem = function () {
      return items().filter(':visible')
    }

    var findItem = function (item, wrappedItem) {
      return (item.length > 0) ? item : wrappedItem
    }

    var nextItem = function () {
      return findItem(currentItem().next(), items().first())
    }

    var prevItem = function () {
      return findItem(currentItem().prev(), items().last())
    }

    var updatePage = function (idx, count) {
      $currentPage.text(idx)
      $totalPages.text(count)
    }

    var updateItems = function ($item) {
      if ($item.length > 0) {
        items().hide()
        $item.show()
        updatePage($item.index() + 1, items().length)
      } else {
        $carousel.remove()
      }
    }

    $nextPageButton.on('click', function () { updateItems(nextItem()) })

    $prevPageButton.on('click', function () { updateItems(prevItem()) })

    $dismissItemAnchors.on('ajax:success', function() {
      $(this).closest(items()).remove()
      updateItems(nextItem())
    })
  })
})(window.jQuery)
