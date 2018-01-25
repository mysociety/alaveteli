// Handles submission of the search form via ajax
(function($, BatchAuthoritySearch, DraftBatchSummary){
  BatchAuthoritySearch.Browse = {};

  var SearchEvents = BatchAuthoritySearch.Events;
  var DraftEvents = DraftBatchSummary.Events;
  var $search,
      $draft;
  var listItemSelector = '.batch-builder__list__item';
  var groupSelector = '.batch-builder__list__group';
  var closedClass = 'batch-builder__list__group--closed';

  var toggleCaret = function toogleCaret(group) {
    group.toggleClass(closedClass);
  };

  var fetchBodies = function fetchBodies(url, group) {
    $.ajax({
      url: url,
      dataType: 'html',
      success: function (data) {
        group.append(data);
        toggleCaret(group);
        $draft.trigger(DraftEvents.bodyAdded);
        $search.trigger(SearchEvents.domUpdated);
      }
    });
  }

  var bindListItemAnchors = function bindListItemAnchors() {
    $('.batch-builder__list__item__anchor', $search).on('click', function (e) {
      e.preventDefault();

      var listItem = $(this).parent(listItemSelector);
      var group = listItem.parent(groupSelector);
      var childList = listItem.siblings('ul');

      if (childList.is('*')) {
        toggleCaret(group);
      } else {
        var url = $(this).attr('href');
        fetchBodies(url, group);
      }
    });
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $draft = DraftBatchSummary.$el;

    $search.on(SearchEvents.rendered, bindListItemAnchors);
    bindListItemAnchors();
  });
})(window.jQuery,
   window.AlaveteliPro.BatchAuthoritySearch,
   window.AlaveteliPro.DraftBatchSummary);
