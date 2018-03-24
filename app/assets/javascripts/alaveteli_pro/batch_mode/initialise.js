(function($, AlaveteliPro) {
  var BatchMode = AlaveteliPro.AlaveteliPro = {};
  var $el;
  var namespace = AlaveteliPro.Events.namespace + ':BatchMode';
  var Events = BatchMode.Events = {
    namespace: namespace,
  };

  BatchMode.currentXHR = null;

  // Start a new XHR request, aborts any existing one and triggers a loading
  // event on the root element to tell everything about it.
  BatchMode.startNewXHR = function startNewXHR() {
    if (BatchMode.currentXHR) {
      BatchMode.currentXHR.abort();
    }
    $el.trigger(Events.loading);
  };

  // Bind to the various outcomes of the currentXHR so that we trigger the
  // right events when things happen with it
  BatchMode.bindXHR = function bindXHR() {
    BatchMode.currentXHR.done(function(data) {
      $el.trigger(Events.loadingSuccess, {html: data});
    });
    BatchMode.currentXHR.fail(function(xhr, textStatus) {
      $el.trigger(Events.loadingError, {textStatus: textStatus});
    });
    BatchMode.currentXHR.always(function() {
      $el.trigger(Events.loadingComplete);
    });
  };

  $(function() {
    $el = $('.batch-builder-mode');
    BatchMode.$el = $el;
  });
})(window.jQuery, window.AlaveteliPro);
