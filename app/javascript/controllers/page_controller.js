import { Controller } from "@hotwired/stimulus";
import hljs from "highlight.js";

export default class extends Controller {
  static values = {
    id: String,
    title: String,
    lang: String,
  };

  connect() {
    window.addEventListener("turbo:load", () => {
      hljs.highlightAll();
      this.element.querySelectorAll("pre code").forEach((el) => {
        el.innerHTML = el.innerHTML.replace(/^\n+/, "").replace(/\n+$/, "");
      });
    });
    fetch(`/${this.langValue}/wiki/${this.idValue}`, {
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

    this.wrapBlock();

    window.addEventListener(
      "turbo:before-stream-render",
      this.wrapBlock.bind(this),
    );

    this.element
      .querySelector(".prose")
      .addEventListener("mouseup", this.select.bind(this));
    this.element
      .querySelector(".prose")
      .addEventListener("touchend", this.select.bind(this));
    this.element
      .querySelector(".prose")
      .addEventListener("touchmove", this.hideMenu.bind(this));
  }

  hideMenu() {
    const buttons = document.querySelector("#actionButtons");
    buttons.style.visibility = "hidden";
  }

  select(e) {
    const buttons = document.querySelector("#actionButtons");
    const selection = window.getSelection();

    if (selection.toString().length === 0) {
      buttons.style.visibility = "hidden";
      return;
    }

    buttons.style.visibility = "visible";
    buttons.style.left = e.pageX + 10 + "px";
    buttons.style.top = e.pageY + 10 + "px";

    const jumpButton = document.querySelector("#jumpButton");
    jumpButton.href = `/${this.langValue}/wiki/${encodeURIComponent(
      selection.toString(),
    )}?ref=${this.titleValue}`;

    const digButton = document.querySelector("#digButton");
    digButton.href = `/${this.langValue}/wiki/${encodeURIComponent(
      `${this.titleValue} ${selection.toString()}`,
    )}?ref=${this.titleValue}`;
  }

  wrapBlock() {
    Array.from(this.element.querySelector(".prose").children).forEach((c) => {
      c.classList.add("transition");
      c.classList.add("hover:bg-slate-100");
    });
  }
}
