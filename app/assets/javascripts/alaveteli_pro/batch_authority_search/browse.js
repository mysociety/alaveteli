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

  var openCaret = function openCaret(group) {
    group.removeClass(closedClass);
  };

  var closeCaret = function closeCaret(group) {
    group.addClass(closedClass);
  };

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
        openCaret(group);
        toggleSpinner(group);
        $draft.trigger(DraftEvents.bodyAdded);
        $search.trigger(SearchEvents.domUpdated);
      }
    });
  }

  var bindListItemAnchors = function bindListItemAnchors() {
    $('.batch-builder__list__item__anchor', $search).on('click', function (e) {
      e.preventDefault();

      var listItem = $(this).closest(listItemSelector);
      var group = listItem.closest(groupSelector);
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
    closeCaret(groups);
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
