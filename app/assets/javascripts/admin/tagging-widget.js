$(function() {
  const tags = {
    taglist: undefined,

    getList: function() {
      const url = "/admin/tags/list_for_widget.json";

      if (tags.taglist === undefined) {
        $.ajax(url).done(function(data) {
          tags.taglist = data;
        });
      }
      return tags.taglist;
    },
    searchByText: function(text) {
      tag_list = tags.getList();
      if (tag_list === undefined) {
        return [];
      }
      return tag_list.filter(function(t) {
        return t.t.toLowerCase().includes(text.toLowerCase());
      });
    },
  };

  tags.getList();
  var methods = {
    // Initialize our tagging widget:
    // hide the original input (from rails)
    // and add a div which holds each tag as a span
    // plus a new input which is used to type new values
    init: function(options) {
      const originalInput = $(this);
      originalInput.hide();
      originalInput.after(
        `<div class="tagging-tag-container"><span class="tagging-tags-wrapper"></span><input list="suggested-tags" text="" class="tagging-add-tags" name="add-tags" id="add-tags" placeholder="${options.tagInputPlaceholder}" value="" /><datalist id="suggested-tags"></datalist></div>`
      );

      // initialize tags from values provided by backend
      $.each(originalInput[0].value.split(" "), function(_, value) {
        if (value.length < 1) {
          // prevent an empty string from being considered a tag
          return;
        }
        addTag(
          value,
          options.tagBackgroundColor,
          options.tagColor,
          options.tagBorderColor,
          originalInput
        );
      });

      $(".tagging-tag-container").click(function() {
        $(".tagging-add-tags").focus();
        // start loading the list of tags, as it's likely the user
        // is about to type :)
        tags.getList();
      });

      $(".tagging-add-tags").on("keydown", function(evt) {
        if (
          ["Comma", "Alt", "Control", "ArrowDown", "ArrowUp"].includes(evt.key)
        ) {
          return;
        }
        if ([" ", "Tab", "Enter"].includes(evt.key)) {
          evt.preventDefault();
          // these are "separators" and trigger the addition
          // of a new tag to the list
          var tag = $.trim($(this).val());
          if (tag.length < 1) {
            return false;
          }
          addTag(
            tag,
            options.tagBackgroundColor,
            options.tagColor,
            options.tagBorderColor,
            originalInput
          );
          $(this).val("");
          $(this).focus();
        } else {
          // update the list of suggested tags
          let searchString;
          let suggestedTagsList;

          suggestedTagsList = $("#suggested-tags");
          suggestedTagsList.empty();

          if (evt.key === "Backspace") {
            searchString = $(this).val().slice(0, -1);
          } else {
            searchString = `${$(this).val()}${evt.key}`;
          }

          filteredTags = tags.searchByText(searchString);

          filteredTags.forEach(function(tag) {
            var opt = document.createElement("option");
            opt.value = tag.t;
            suggestedTagsList.append(opt);
          });
        }
      });

      // remove the tag when clicking the cross icon
      $(document).on("click", ".tagging-tag-remove", function() {
        $(this).parent().remove();
        copyTags(originalInput);
        $(".tagging-tags-wrapper").focus();
      });

      return $(".tagging-tag-container").css({
        "border-color": options.tagContainerBorderColor,
        "border-width": ".1em",
        "border-style": "solid",
      });
    },
  };

  // escape toxic characters
  function sanitizeTag(name) {
    return name.
          replace(">", '&gt;').
          replace("<", '&lt;').
          replace("'", '&apos;').
          replace('"', '&quot;');
  }

  // new tags are added as span elements under the div
  function addTag(tagName, tagBgColor, tagColor, tagBorderColor, tagInput) {
    if (document.querySelector(`code[tag-title="${sanitizeTag(tagName)}"]`) === null) {
      var closeBtn = document.createElement("span");
      closeBtn.className = "tagging-icon-close";
      var link = document.createElement("a");
      link.className = "tagging-tag-remove";
      link.setAttribute("title", "Remove tag");
      link.appendChild(closeBtn);
      var tagItem = document.createElement("code");
      tagItem.className = "tagging-tags";
      tagItem.setAttribute("tag-title", sanitizeTag(tagName));
      tagItem.style.backgroundColor = tagBgColor;
      tagItem.style.color = tagColor;
      tagItem.style.borderColor = tagBorderColor;
      tagItem.appendChild(document.createTextNode(tagName));
      tagItem.appendChild(link);
      $(".tagging-tags-wrapper").append(tagItem);
      copyTags(tagInput);
    }
  }

  // copy tags to the original input as a string
  // to respect the original logic, so that validating the form
  // still works with rails
  function copyTags(tagInput) {
    var listOfTags = [];
    $(".tagging-tags").each(function() {
      listOfTags.push($(this).text().trim());
    });
    tagInput.val(listOfTags.join(" "));
  }

  $.fn.TagsWidget = function(methodOrOptions) {
    if (!this.length) {
        return;
    }
    if (typeof methodOrOptions === "object" || !methodOrOptions) {
      return methods.init.apply(this, arguments);
    } else if (methods[methodOrOptions]) {
      return methods[methodOrOptions].apply(
        this,
        Array.prototype.slice.call(arguments, 1)
      );
    } else {
      $.error("Invalid method " + methodOrOptions + " for TagsWidget.");
    }
  };

  const widgetOptions = {
    tagInputPlaceholder: "add tags...",
    tagContainerBorderColor: "#d3d3d3",
    tagBackgroundColor: "#f7f7f9",
    tagColor: "#d14",
    tagBorderColor: "#e1e1e8",
  };

  $(document).ready(function () {
    $("#public_body_tag_string").TagsWidget(widgetOptions);
    $("#info_request_tag_string").TagsWidget(widgetOptions);
    $("#admin_user_tag_string").TagsWidget(widgetOptions);
    $("#outgoing_message_tag_string").TagsWidget(widgetOptions);
    $("#incoming_message_tag_string").TagsWidget(widgetOptions);
  });
});
