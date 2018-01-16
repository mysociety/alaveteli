// Based on https://gist.githubusercontent.com/antitoxic/9156ae5a4531fce46ad1/raw/1c772f5845d4f56697400518b5897dd879902f41/no_results.selectize.js

Selectize.define('no_results', function (options) {
  var KEY_LEFT = 37
  var KEY_UP = 38
  var KEY_RIGHT = 39
  var KEY_DOWN = 40
  var ignoreKeys = [KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN]
  var self = this

  options = $.extend({
    message: 'No results found',
    html: function (data) {
      return '<div class="selectize-dropdown-content selectize-no-results">' + data.message + '</div>'
    }
  }, options)

  self.on('type', function () {
    if (!self.hasOptions && self.loading === 0 && self.lastValue.length > 2) {
      self.open()
      self.$empty_results_container.show()
    } else {
      self.$empty_results_container.hide()
    }
  })

  self.onKeyUp = (function () {
    var original = self.onKeyUp

    return function (e) {
      if (ignoreKeys.indexOf(e.keyCode) > -1) return
      self.isOpen = false
      original.apply(self, arguments)
    }
  })()

  self.onBlur = (function () {
    var original = self.onBlur

    return function () {
      original.apply(self, arguments)
      self.$empty_results_container.hide()
    }
  })()

  self.setup = (function () {
    var original = self.setup
    return function () {
      original.apply(self, arguments)
      self.$empty_results_container = $(
        options.html($.extend({
          classNames: self.$input.attr('class')
        }, options))
      )
      self.$empty_results_container.hide()
      self.$dropdown.append(self.$empty_results_container)
    }
  })()
})
