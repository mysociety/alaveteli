// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

// Disable Turbo Drive background page loads when hovering over links
Turbo.session.drive = false

// Disable old jQuery UJS event handling, allowing Turbo to handle instead
$(document).off("click.rails");
$(document).off("change.rails");
$(document).off("submit.rails");
