import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    id: String,
  };

  connect() {
    this.selection = null;
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

    this.element
      .querySelector(".prose")
      .addEventListener("mouseup", this.select.bind(this));
    this.element
      .querySelector(".prose")
      .addEventListener("touchend", this.select.bind(this));
  }

  select(e) {
    const buttons = document.querySelector("#actionButtons");
    const selection = window.getSelection();

    this.unwrap();

    if (selection.toString().length === 0) {
      buttons.style.display = "none";
      this.selection = null;
      return;
    }

    this.selection = selection;

    buttons.style.display = "flex";
    buttons.style.left = e.pageX + "px";
    buttons.style.top = e.pageY + "px";

    const range = selection.getRangeAt(0);
    const docFragment = range.extractContents();

    const span = document.createElement("span");
    span.id = "expand";
    span.appendChild(docFragment);
    range.insertNode(span);
    selection.removeAllRanges();
    let newRange = document.createRange();
    newRange.selectNode(span);
    selection.addRange(newRange);

    const readButton = document.querySelector("#readButton");
    readButton.href = `/wiki/${selection.toString()}`;

    const expandButton = document.querySelector("#expandButton");
    expandButton.href = `/wiki/${this.idValue}/expand?text=${encodeURIComponent(
      document.querySelector(".prose").innerHTML
    )}`;
  }

  unwrap() {
    console.log("unwrap");
    const spans = document.querySelectorAll("#expand");
    spans.forEach((span) => {
      span.outerHTML = span.innerHTML;
    });
  }
}
