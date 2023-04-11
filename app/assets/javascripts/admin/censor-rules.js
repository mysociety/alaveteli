$(function () {
  $('#js-use-previous-comment').click(function (e) {
    var textArea = $($(this).data('target'));
    var lastEditComment = textArea.data('last-edit-comment');
    textArea.val(lastEditComment);
    e.preventDefault();
  })
});
