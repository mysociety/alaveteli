(function($) {
  var RefusalWizard = function(target, options) {
    this.$el = $(target);

    var defaults = {
      debug: false,

      questionClass: "wizard__question",
      questionAnswerableClass: "wizard__question--answerable",
      questionAnsweredClass: "wizard__question--answered",

      suggestionClass: "wizard__suggestion",
      suggestionSuggestedClass: "wizard__suggestion--suggested",

      actionClass: "wizard__action",
      actionActiveClass: "wizard__action--active",
      actionSuggestedClass: "wizard__action--suggested",

      nextStepClass: "wizard__next-step",
      nextStepSuggestedClass: "wizard__next-step--suggested",
      nextStepTitleClass: "wizard__next-step__title"
    };

    this.options = $.extend(true, defaults, options);

    this._init(target);

    return this;
  };

  RefusalWizard.prototype._init = function(target) {
    var wizard = this;

    wizard.$blocks = wizard.$el.find(
      "." +
        wizard.options.questionClass +
        ", ." +
        wizard.options.suggestionClass
    );
    wizard.$questions = wizard.$el.find("." + wizard.options.questionClass);
    wizard.$suggestions = wizard.$el.find("." + wizard.options.suggestionClass);

    wizard.$actions = wizard.$el.find("." + wizard.options.actionClass);
    wizard.$next_steps = wizard.$el.find("." + wizard.options.nextStepClass);

    wizard._setupBlocks();
    wizard._setupQuestions();
    wizard._setupNextSteps();

    wizard._update();
  };

  RefusalWizard.prototype._setupBlocks = function() {
    var wizard = this;

    wizard.$blocks.each(function() {
      this.block = $(this).data("block");
      this.dependents = function($blocks) {
        return wizard._dependentsOf($blocks, this);
      };

      if (wizard.options.debug) {
        var show_if = $(this).data("show-if") || [];
        show_if = show_if.map(function(s) {
          return '"' + s.id + "=" + s.value + '"';
        });
        $(this).prepend(
          "{ id: " +
            this.block +
            ", show_if: [" +
            show_if.join(", ") +
            "] }" +
            "<br>"
        );
      }
    });
  };

  RefusalWizard.prototype._setupQuestions = function() {
    var wizard = this;

    wizard._resetQuestion(wizard.$questions);

    wizard.$questions.each(function() {
      this.values = function() {
        return wizard._valuesOf(this);
      };
    });

    wizard.$questions.on("change", function() {
      wizard._update($(this));
    });
  };

  RefusalWizard.prototype._setupNextSteps = function() {
    var wizard = this;
    var $titles = wizard.$el.find("." + wizard.options.nextStepTitleClass);

    $titles.on("click", function(event) {
      event.preventDefault();

      var $action = $(this).siblings("." + wizard.options.actionClass);
      var active = $action.hasClass(wizard.options.actionActiveClass);

      wizard.$actions.removeClass(wizard.options.actionActiveClass);
      if (!active) $action.addClass(wizard.options.actionActiveClass);
    });
  };

  RefusalWizard.prototype._valuesOf = function(question) {
    return $(question)
      .find("input:checked, option:selected")
      .map(function() {
        return $(this).val();
      })
      .get();
  };

  RefusalWizard.prototype._dependentsOf = function($blocks, question) {
    var wizard = this;

    return $blocks.filter(function() {
      var $block = $(this);
      var showIfArray = $block.data("show-if");

      // can't be a dependent if already answered
      // FIXME: this assumes suggestions won't have input/option elements
      if ($block.find("input:checked, option:selected").length) {
        return false;
      }

      if (!showIfArray) {
        wizard.log("MATCH:", this.block, "no show-if");
        return true;
      }

      for (var i = 0, len = showIfArray.length; i < len; i++) {
        var showIf = showIfArray[i];

        // can't be a dependent if showIf is for a different question ID
        // check showIf operator
        if (
          showIf.id === question.block &&
          showIf.operator === "is" &&
          question.values().indexOf(showIf.value) > -1
        ) {
          wizard.log("MATCH:", this.block, showIf, question.values());
          return true;
        }
      }

      return false;
    });
  };

  RefusalWizard.prototype._dependents = function($blocks) {
    var wizard = this;

    var dependents = [];

    wizard.$questions.each(function() {
      // loop through dependents backwards
      $(this.dependents($blocks).get().reverse()).each(function() {
        if (dependents.indexOf(this) === -1) dependents.unshift(this);
      });
    });

    return dependents;
  };

  RefusalWizard.prototype._nextQuestion = function() {
    var wizard = this;

    var questions = wizard._validQuestions();
    var next_question = questions[0]; // questions.length - 1

    if (next_question) {
      wizard.log("NEXT QUESTION:", next_question.block);
      return $(next_question);
    }
  };

  RefusalWizard.prototype._validQuestions = function() {
    var wizard = this;

    var dependents = wizard._dependents(wizard.$questions);
    wizard.log("VALID QUESTIONS:", dependents);
    return $(dependents);
  };

  RefusalWizard.prototype._validSuggestions = function() {
    var wizard = this;

    var dependents = wizard._dependents(wizard.$suggestions);
    wizard.log("VALID SUGGESTIONS:", dependents);
    return $(dependents);
  };

  RefusalWizard.prototype._update = function($current_question) {
    var wizard = this;
    var $next_question = wizard._nextQuestion();

    if ($current_question) {
      $current_question.removeClass(wizard.options.questionAnswerableClass);
      $current_question.addClass(wizard.options.questionAnsweredClass);

      var $obsolete_questions = $current_question.nextAll(
        "." + wizard.options.questionClass
      );
      wizard._resetQuestion($obsolete_questions);
    }

    if ($next_question) {
      $next_question.addClass(wizard.options.questionAnswerableClass);
      $next_question.find("input[value=yes]").focus();
    }

    if ($current_question && $next_question) {
      $current_question.after($next_question);
    }

    // Load valid suggestions after wizard._resetQuestion has been called
    var $suggestions = wizard._validSuggestions();

    wizard.$actions.removeClass(wizard.options.actionSuggestedClass);
    wizard.$suggestions.removeClass(wizard.options.suggestionSuggestedClass);
    wizard.$next_steps.removeClass(wizard.options.nextStepSuggestedClass);

    $suggestions.addClass(wizard.options.suggestionSuggestedClass);
    var $active_actions = wizard.$actions.filter(
      ":has(." + wizard.options.suggestionSuggestedClass + ")"
    );

    $active_actions.addClass(wizard.options.actionSuggestedClass);
    $active_actions.each(function() {
      wizard.$next_steps
        .filter('[data-block="' + $(this).data("block") + '"]')
        .addClass(wizard.options.nextStepSuggestedClass);
    });

    wizard.$actions.find('input[name^="refusal_advice"]').val(false);
    $suggestions.find('input[name^="refusal_advice"]').val(true);
  };

  RefusalWizard.prototype._resetQuestion = function($question) {
    var wizard = this;
    $question.removeClass(wizard.options.questionAnswerableClass);
    $question.removeClass(wizard.options.questionAnsweredClass);

    var $options = $question.find("input, option");
    $options.prop("checked", false);
    $options.prop("selected", false);
  };

  RefusalWizard.prototype.log = function() {
    var wizard = this;
    if (wizard.options.debug) {
      var args = Array.prototype.slice.call(arguments);
      console.log.apply(console, args);
    }
  };

  $.fn["refusalWizard"] = function(methodOrOptions) {
    if (!$(this).length) {
      return $(this);
    }

    var instance = $(this).data("refusalWizard");
    var wantsToCallPublicMethod =
      instance &&
      methodOrOptions.indexOf("_") != 0 &&
      instance[methodOrOptions] &&
      typeof instance[methodOrOptions] == "function";
    var wantsToInitialise =
      typeof methodOrOptions === "object" || !methodOrOptions;

    if (wantsToCallPublicMethod) {
      return instance[methodOrOptions](
        Array.prototype.slice.call(arguments, 1)
      );
    } else if (wantsToInitialise) {
      instance = new RefusalWizard($(this), methodOrOptions);
      $(this).data("refusalWizard", instance);
      return $(this);
    } else if (!instance) {
      $.error(
        "Plugin must be initialised before using method: " + methodOrOptions
      );
    } else if (methodOrOptions.indexOf("_") == 0) {
      $.error("Method " + methodOrOptions + " is private!");
    } else {
      $.error("Method " + methodOrOptions + " does not exist.");
    }
  };

  $(".js-wizard").refusalWizard({ debug: false });
})(window.jQuery);
