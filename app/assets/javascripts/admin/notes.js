document.addEventListener("DOMContentLoaded", function () {
  var selectElement = document.getElementById("note_style");

  function updateBodyVisibility(body, rich) {
    if (selectElement.value === "original") {
      body.style.display = "block";
      rich.style.display = "none";
    } else {
      body.style.display = "none";
      rich.style.display = "block";
    }
  }

  function updateAllBodyVisibility() {
    var localeDivs = document.querySelectorAll("[id^='div-locale-']");

    localeDivs.forEach(function (div) {
      var body = div.querySelector(".note--body");
      var rich = div.querySelector(".note--rich_body");

      if (body && rich) {
        updateBodyVisibility(body, rich);
      }
    });
  }

  if (selectElement) {
    selectElement.addEventListener("change", updateAllBodyVisibility);
    updateAllBodyVisibility();
  }
});
