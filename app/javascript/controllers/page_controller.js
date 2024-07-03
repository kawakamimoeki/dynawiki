import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    id: String,
  };

  connect() {
    fetch(`/wiki/${this.idValue}`, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document
          .querySelector('meta[name="csrf-token"]')
          .getAttribute("content"),
      },
      method: "POST",
    })
      .then((response) => response.text())
      .then((html) => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, "text/html");
        document.body.insertAdjacentHTML("beforeend", doc.body.innerHTML);
      });

    window.addEventListener("mouseup", this.select);
  }

  select(e) {
    const button = document.querySelector("#actionButton");

    if (window.getSelection().toString().length === 0) {
      button.style.display = "none";
      return;
    }

    button.style.display = "flex";
    button.style.left = e.pageX + "px";
    button.style.top = e.pageY + "px";
    button.href = `/wiki/${window.getSelection().toString()}`;
  }
}
