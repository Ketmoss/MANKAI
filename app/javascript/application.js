// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"
import "channels"

document.addEventListener("turbo:load", () => {
  const flash = document.querySelector(".flash-message");
  if (flash) {
    setTimeout(() => {
      flash.style.transition = "opacity 0.5s";
      flash.style.opacity = "0";
      setTimeout(() => flash.remove(), 500);
    }, 4000); // disparaît après 4s
  }
});
