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
  var loadingClass = 'batch-builder__list__group--loading';

  var toggleCaret = function toogleCaret(group) {
    group.toggleClass(closedClass);
  };

  var toggleSpinner = function toggleSpinner(group) {
    group.toggleClass(loadingClass);
  };

  var fetchBodies = function fetchBodies(url, group) {
    toggleSpinner(group);
    $.ajax({
      url: url,
      dataType: 'html',
      success: function (data) {
        group.append(data);
        toggleCaret(group);
        toggleSpinner(group);
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

  var collapseTopLevelGroups = function collapseTopLevelGroups() {
    var groups = $('.batch-builder__list > .batch-builder__list__group');
    toggleCaret(groups);
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $draft = DraftBatchSummary.$el;

    $search.on(SearchEvents.rendered, bindListItemAnchors);

    collapseTopLevelGroups();
    bindListItemAnchors();
  });
})(window.jQuery,
   window.AlaveteliPro.BatchAuthoritySearch,
   window.AlaveteliPro.DraftBatchSummary);
